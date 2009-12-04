require 'monitor'
module Lulz
	class World

		attr_reader :predicates
		attr_reader :objects
		attr_reader :mutex
		
		@@real_world=nil
		def initialize
			@object_create_callback=nil 
			@predicate_add_callback=nil
			@predicates=[]
			@predicate_exists={}
			@predicates_by_name={}
			@predicates_by_subject={}
			@predicates_by_object={}
			@probabilties={} 
			@unclean=[]
			@unclean_predicates=[]     
			@objects={}
			@objects_of_interest=[]
			@search_relevances={}
			@agent_processed_list={}
			@profiles_graph=Graph.new
			@match_scores={}
			@direct_match_scores={}
			@priors={}
			@search_relevance_scores={}
			@mutex=Monitor.new
			@dependencies_by_profile={}
			@defined_matches={}
			@graph_paths={}
			@direct_match_hashes={}
		end

		def self.instance
			@@real_world=World.new if @@real_world.blank?
			return @@real_world
		end

		def save
			filez=Dir.glob("#{LULZ_DIR}/data/world.*")
			filez.sort {|a,b| a<=>b }
			number=filez.last.split(".").last.to_i rescue 0
			number=number+1
			number=sprintf("%04d",number)
			File.open("#{LULZ_DIR}/data/world.#{number}", 'w') do |out|
				   Marshal.dump(self, out)
			end
		end

		def self.load(file)
			@@real_world=ZAML.load_file(file)
		end
		def sorted_profiles
			sorted=self.profiles.clone.sort { |a1,b1| matches[a1].to_f <=> matches[b1].to_f }.reverse
			return sorted
		end

		def graph_path(profile)
			prev=@graph_paths[profile]
			return [] if prev.nil?
			prev_path=[]
			prev_path=graph_path(prev)
			return [prev]+graph_path(prev)
		end


		def matches
			@match_scores[@objects_of_interest.first]||={}
			return @match_scores[@objects_of_interest.first]
		end

		def set_match(profile,value)
			@defined_matches[profile]=value
		end

		def match_value(profile)
			return  @defined_matches[profile]
		end

		def match_value_known?(profile)
			return (@defined_matches[profile]===true or @defined_matches[profile]===false)
		end

		def profiles
			profiles=self.objects.select { |o| o.is_a? Profile }
			profiles
		end

		def search_relevant?(pred)
			return true if !@search_relevance_scores[pred.object].blank? and @search_relevance_scores[pred.object]>0.1
			return true if !@search_relevance_scores[pred.subject].blank? and @search_relevance_scores[pred.subject]>0.1
			return false
		end

		def update_matches(profile,preds)
			profiles=sorted_profiles.clone
			profile=profiles - [profile]
			@priors[profile]||={}
			profiles.each do |profile_b|
				@priors[profile_b]||={}
				prior=@priors[profile][profile_b]

				prior=@priors[profile_b][profile] if profile_b.person_id < profile.person_id
				match=IdentityBayes.calculate_match(profile, profile_b)
				@priors[profile][profile_b]=match if profile_b.person_id > profile.person_id
				@priors[profile_b][profile]=match if profile_b.person_id < profile.person_id
				cost=(1.0/match) rescue 999999999999
				cost=999999999999 if match==0 # infinity is a very large number ;)
				@profiles_graph.add_undirected_edge(profile, profile_b,cost)
			end
		end

		def update_match_scores
			recalc_graph
		end

		def recalc_graph
			@objects_of_interest.each do |objoi|
				graph=@profiles_graph.probabalistic_shortest_paths(objoi)
				distances=graph[1]
				@graph_paths=graph[0]
				h=Hash.new
				distances.each { |k,v|  h[k]=1.0/v }
				@match_scores[objoi]=h

			end
		end

		def recalc_all

			@match_scores[@objects_of_interest.first]||={}
			@match_scores[@objects_of_interest.first][@objects_of_interest.first]=1.0
			self.profiles.each { |profile| recalc_matches(profile) }
		end

		def recalc_matches(profile)
			obj_oi=@objects_of_interest.first
			@match_scores[obj_oi] ||= {}	
			old_matches=@match_scores[obj_oi].clone
			cutoff=Blackboard.instance.options[:graph_cutoff]
			profiles=self.sorted_profiles.clone
			profiles.delete profile
			graph_changed=false
			t=Time.now
			profiles.each do |profile_b|
				sm, bm = (profile.person_id < profile_b.person_id ? [profile, profile_b] : [profile_b, profile])
				@direct_match_scores[sm] ||= {}
				@direct_match_hashes[sm] ||= {}
				direct_score=@direct_match_scores[sm][bm] rescue nil
				direct_score=nil if !direct_score.nil? and (@direct_match_hashes[sm][bm]!=[sm._predicates.length,bm._predicates.length])
				if match_value(profile)===false or match_value(profile_b)===false or (self.matches[profile_b].to_f<=cutoff and not graph_changed and not (@objects_of_interest.include?(profile_b) or @objects_of_interest.include?(profile)) )
					match=0.0
				elsif match_value(profile)===true and @objects_of_interest.include?(profile_b)
					match=1.0
				elsif !direct_score.nil?
					match=direct_score
				else
					match=IdentityBayes.calculate_match(profile,profile_b)
					@direct_match_scores[sm][bm]=match
					@direct_match_hashes[sm][bm]=[sm._predicates.length,bm._predicates.length]
				end
				cost=(1.0/match) rescue 999999999999
				cost=999999999999 if match==0 # infinity is a very large number ;)
				if @objects_of_interest.include?(profile_b) or @objects_of_interest.include?(profile)
					@profiles_graph.add_undirected_edge(profile, profile_b,cost)
					obj=@objects_of_interest.include?(profile_b) ? profile_b : profile
					mt=@objects_of_interest.include?(profile_b) ? profile : profile_b
					@match_scores[obj][mt]=match
				elsif match>cutoff

					@profiles_graph.add_undirected_edge(profile, profile_b,cost)
					graph_changed=true
				else
					@profiles_graph.delete_undirected_edge(profile, profile_b)
				end
			end
			STDOUT.flush
			if graph_changed
				t=Time.now
				recalc_graph
				STDOUT.flush
			end
			new_matches=@match_scores[obj_oi]
			t=Time.now

			changed_profiles=new_matches.keys.select { |k| old_matches[k].nil? or new_matches[k]!=old_matches[k] }	
			changed_profiles << obj_oi if profile==obj_oi
			dirty_preds=profile._predicates
			changed_profiles.each do |profile|
				@dependencies_by_profile[profile] ||= []
				dirty_preds=dirty_preds+(@dependencies_by_profile[profile].map{|obj| self.predicates_by_subject(obj)}.flatten)
			end

			Blackboard.instance.action_queue.add_dirty_predicates(dirty_preds)

		end

		def objects
			obs=@objects.keys
			return obs
		end

		def search_relevance(pred,explain=false)
			highest=0.0
			deps,score_subject=relevance_to_objoi(@objects_of_interest.first,pred.subject,[],explain)
			return score_subject
		end


		def relevance_to_objoi(objoi,object,checked=[],explain=false)
			dependencies=[]
			object=normalize_object(object) 
			puts "relevance for #{object.to_s} #{object.hash} (#{object.class.to_s})" if explain
			if object.nil?
				puts "Object is nil!" if explain
				return [],0.0
			end
			checked=checked.clone << object
			puts "checked #{checked}" if explain
			if @objects_of_interest.include?(object)
				puts "is object of interest" if explain
				return [],1.0
			end
			if object.is_a?(Profile) and objoi.is_a?(Profile)
				puts "is person" if explain
				return [],0.0 if @match_scores[objoi].nil?
				return [],0.0 if @match_scores[objoi][object].nil?
				return [],@match_scores[objoi][object]
			end
			predicates=predicates_by_object(object)
			predicates=[] if predicates.nil?
			subjects=predicates.map{ |p| p.subject }
			subjects=subjects - checked

			highest=0.0
			found_person=false
			puts "no subjects!" if subjects.empty? and explain
			subjects.each do |subject|
				puts "looking at subject #{subject.to_s} with found_person #{found_person}" if explain
				if subject.is_a? Profile
					score=relevance_to_objoi(objoi,subject,checked,explain)
					dependencies=[] unless found_person
					highest=score[1] unless found_person or highest>score[1]
					dependencies=dependencies+[subject]
					puts "found person" if explain
					found_person=true
					next
				elsif found_person
					puts "found person true, skipping" if explain
					next
					puts "search upwards" if explain
				end
				deps,score=relevance_to_objoi(objoi,subject,checked,explain)
				highest=score if score>highest
				dependencies=dependencies+deps	
				puts "highest is currently #{highest}" if explain
			end
			dependencies.uniq.each {|dep|
				@dependencies_by_profile[dep] ||= []
				@dependencies_by_profile[dep] << object unless @dependencies_by_profile[dep].include?(object)
			}

			return [],0.0 if highest.nil?
			return dependencies,highest	


		end

		def calculate_search_relevance
			@objects_of_interest.each do |objoi|
				if objoi.is_a? Profile
					distances=@profiles_graph.probabalistic_shortest_paths(objoi)[1]
					h=Hash.new
					distances.each { |k,v| h[k]=1.0/v }
					@match_scores[objoi]=h
				end

			end

			objects.each do |obj|
				if @objects_of_interest.include?(obj)
					@search_relevance_scores[obj]=1.0
					next
				end
				highest=0.0
				@objects_of_interest.each do |objoi|
					score=relevance_to_objoi(objoi, obj,true)
					highest=score if score>highest
				end
				@search_relevance_scores[obj]=highest
			end
		end 

		def on_object_create(&block)
			@object_create_callback=block
		end

		def on_empty_queue(&block)
			@empty_queue_callback=block
		end

		def on_predicate_add(&block)
			@predicate_add_callback=block
		end

		def list_processed(agent_klass)
			return [] if @agent_processed_list[agent_klass.to_s].nil?
			return @agent_processed_list[agent_klass.to_s].keys
		end

		def set_processed(agent_klass,object)
			@agent_processed_list[agent_klass.to_s] = {} if @agent_processed_list[agent_klass.to_s].nil?
			@agent_processed_list[agent_klass.to_s][normalize_object(object)]=true
		end



		def is_processed?(agent_klass,object)
			return false if @agent_processed_list[agent_klass.to_s].nil?
			return @agent_processed_list[agent_klass.to_s].key?(normalize_object(object))
		end

		def object_of_interest(obj)
			@objects_of_interest.push normalize_object(obj) unless  @objects_of_interest.include? normalize_object(obj)
		end

		def unclean_objects
			@unclean
		end


		def unclean_predicates
			@unclean_predicates
		end

		def clean(obj)
			obj._lulz_unclean=false
			@unclean.delete(obj)
			@unclean_predicates.delete(obj) if obj.is_a? Predicate
		end

		def add(obj)
			@mutex.synchronize {
				unless @objects.key?(obj)
					obj.person_id if obj.is_a? Profile
					@objects[obj]=obj

					@object_create_callback.call(obj) unless @object_create_callback.nil?
				end
			}
		end

		def unclean(obj)
			if obj.is_a?(Predicate)
				@unclean_predicates.push obj

				obj._lulz_unclean=true
			else
				@unclean.push obj #unless @unclean.include?(obj)
			end

		end



		def add_predicate(p)
			@mutex.synchronize {
				normalize_predicate!(p)
				return nil if @predicate_exists.key?(p.short_s)
				return nil if p.object.blank?
				p._world=self
				@predicates << p
				@predicate_exists[p.short_s]=true

				@predicates_by_name[p.name] ||= []
				@predicates_by_name[p.name] << p

				@predicates_by_subject[p.subject] ||= []
				@predicates_by_subject[p.subject] << p

				@predicates_by_object[p.object] ||= []
				@predicates_by_object[p.object] << p
			}
			@predicate_add_callback.call(p) unless @predicate_add_callback.nil?
			return p
		end

		def predicates_by_subject(subject)
			preds=nil 
			normal=normalize_object(subject)
			preds=@predicates_by_subject[normal] 
			preds=[] if @predicates_by_subject[normal].nil?
			return preds
		end

		def predicates_by_object(object)
			preds=nil
			normal=normalize_object(object)
			preds=@predicates_by_object[normal] 

			preds=[] if @predicates_by_object[normal].nil?
			if preds.length==0
				#pp @predicates_by_object
			end
			return preds
		end




		alias :<< :add_predicate
		def normalize_object(obj)
			normal=nil 
			@mutex.synchronize{
				normal=@objects[obj] unless @objects[obj].nil?
				add obj if normal.nil? 
				normal=obj if normal.nil?
			}
			return normal
		end


		private 

		def normalize_predicate!(predicate)
			predicate.object=normalize_object(predicate.object) 
			predicate.subject=normalize_object(predicate.subject)
		end

	end
end
