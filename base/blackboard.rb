require 'singleton'
module Lulz

	class Blackboard
		include Singleton
		attr_reader :world
		attr_accessor :options
		attr_accessor :max_threads
		attr_accessor :agents_ran
		attr_accessor :created_predicates
		attr_accessor :action_queue
		@@main_loop_mutex=Monitor.new


		def status(s)
			unless self.options[:silent]
				print s
				STDOUT.flush
			end
		end

		def status_agent(agent)
			status(".") if agent.transformer?
			status("*") if agent.searcher?
			status("=") if agent.parser?
		end	

		def sorted_profiles
			matches=self.world.matches
			sorted=self.profiles.clone.sort { |a1,b1| matches[a1].to_f <=> matches[b1].to_f }.reverse
			return sorted
		end

		def run(threads=nil)
			threads=@options[:threads] if threads.nil?
			self.max_threads=threads
			@recalculator=Thread.new { Agent.process_recalc_queue; }
			@recalculator.priority=3
			World.instance.recalc_all
			@@main_loop_mutex.synchronize{
				unless @main_loop_running
					unless @options[:block_until_finished]
						@main_loop_thread=Thread.new { self.main_loop }
					else
						self.main_loop
					end
				end
			}

		end

		def pause
			self.max_threads=0
		end

		def is_running?
			return @main_loop_running
		end



		def main_loop
			@@main_loop_mutex.synchronize{ @main_loop_running=true }
			threadz = []
			single_threaded=(options[:single_thread]===true)
			waited=0
			Thread.current.priority=4
			timeout=options[:timeout].to_i
			hard_timeout=options[:hard_timeout].to_i
			has_timeout=false
			start=Time.now
			while true do
				num_threads=Agent.running_agents.keys.length
				
				if timeout!=0 and Time.now>(start+timeout)
					has_timeout=true
				end

				if hard_timeout!=0 and Time.now>(start+hard_timeout)
					break;
				end
				if has_timeout
					next_action=nil
				else
					next_action=action_queue.next if next_action.nil?
					STDOUT.flush
				end
				break if (next_action.nil? or has_timeout) and single_threaded 
				unless single_threaded
					waited+=1 if next_action.nil? and num_threads<=0 and Agent.recalc_queue.empty?
					Blackboard.instance.status("F") if num_threads>=max_threads
					Agent.list_agents if num_threads>=max_threads
					Blackboard.instance.status("W") if next_action.nil? and !has_timeout
					Blackboard.instance.status("T") if next_action.nil? and has_timeout

					unless (num_threads<max_threads and (!next_action.nil?))
						break if waited>3
						sleep 2

						next;
					end
				end
				next if has_timeout
				waited=0 

				agent_klass, pred = next_action
				next_action=nil
				next unless pred.runnable_by?(agent_klass)
				@processed[agent_klass]=[] if @processed[agent_klass].nil?
				@processed[agent_klass] << pred

				unless single_threaded
					agent_klass.run(pred)
				else
					begin
						agent.process(object)
					rescue Exception => e
						ERROR_LOG.error e
						ERROR_LOG.error e.backtrace.join("\n")
					end

				end
			end
			@recalculator.kill
			Agent.kill_all
			@world.update_match_scores
			@queue_empty_callback.call unless @queue_empty_callback.nil?
		end

		def total_predicate_time_spent(pred)
			@created_predicates[pred].sum { |agent| total_agent_time_spent(agent) }
		end

		def total_agent_time_spent(agent)
			time=agent.time_ran
			time=time+agent.produced_predicates.sum { |pred| total_predicate_time_spent(pred) }
			return time
		end

		def save_predicate_statistics

			agent_times={}
			agent_matches={}
			predicate_matches={}
			predicate_times={}
			predicates_ran={}
			successful_predicates=[]
			produced_objects={}
			matches=profiles.select { |p| p.is_match? }
			predicates=world.predicates
			pred_length=predicates.length
			check_point_length=pred_length.to_f/10.0
			check_point=check_point_length
			index=0
			puts "Saving run profile data for #{predicates.length} predicates... "
			predicates.each do |pred|
				chain=pred.to_chain
				ran_agents=pred.ran_by.map { |r| ObjectType.cache_find_or_create_by_name(r.class.to_s) }
				predicates_ran[chain.id] ||= []
				predicates_ran[chain.id]+=ran_agents
				tested_agents=pred.tested_agents.map  { |t| ObjectType.cache_find_or_create_by_name(t.to_s) }
				tested_agents=((tested_agents & chain.agents) + ran_agents + predicates_ran[chain.id]).uniq
				tested_agents.each do |agent|
					tested=chain.markov_agent_run_profiles.find_or_create_by_agent_id(agent.id)
					tested.tried=tested.tried+1
					tested.ran=tested.ran+1 if ran_agents.include?(agent)
					tested.save
				end
				index=index+1
				if index>check_point
					check_point=check_point+check_point_length
					print "%#{((index.to_f/pred_length)*100).to_i} "
				end

			end
			puts "Done!"
			@world.objects.each do |obj|

				pred1=@world.predicates_by_subject(obj).first 
				pred2=@world.predicates_by_object(obj).first
				next if pred1.nil? and pred2.nil?
				if pred2.nil? or (!pred1.nil? and pred1.created_at < pred2.created_at)
					agent = pred1.creator
					puts pred1
				else
					agent = pred2.creator
					puts pred2
				end
				produced_objects[agent]||=[]
				produced_objects[agent]<<obj
			end

			@agents_ran.each do |agent|
				chain=agent.from_predicate.to_chain
				predz={}
				agent.produced_predicates.each do |pred|
					s=pred.search_relevance_to_i
					mp=pred.to_cutout
					predz[mp]||={}
					predz[mp][s]||=0
					predz[mp][s]+=1
				end
				puts "agent #{agent.class.to_s}"
				objz=produced_objects[agent].uniq rescue []
				profilez=objz.select {|o| o.is_a?(Profile)}
				puts "obj length #{objz.length}"
				ag_matches=matches & objz
				puts "ag length #{ag_matches.length}"
				agent_id=ObjectType.cache_find_or_create_by_name(agent.class.to_s).id	 
				prod=chain.markov_produced_objects.find :first, :conditions => {:agent_id => agent_id, :matches => ag_matches.length, :objects => objz.length, :profiles => profilez.length}
				prod=chain.markov_produced_objects.create(:agent_id => agent_id, :matches => ag_matches.length, :objects => objz.length, :profiles => profilez.length) if prod.nil?

				prod.increment!(:count)
				time=prod.markov_agent_time
				time=prod.create_markov_agent_time if time.nil?
				time.increment(:ran)
				time.total_time=time.total_time+agent.time_ran
				time.save
				cutoutz=[]
				allcutz=prod.markov_produced_predicates.map { |p| p.predicate }.uniq
				predz.each do |pred,relevance|
					h={}
					h[:predicate_id]=pred.id
					h[:rel_0_count]=relevance[0].to_i 
					h[:rel_1_count]=relevance[1].to_i
					h[:rel_2_count]=relevance[2].to_i
					h[:rel_3_count]=relevance[3].to_i
					h[:rel_4_count]=relevance[4].to_i
					cutoutz << pred 
					p_produced=prod.markov_produced_predicates.find :first, :conditions => h
					p_produced=prod.markov_produced_predicates.create(h) if p_produced.blank?
					p_produced.increment :count
					p_produced.save
				end
				(allcutz-cutoutz).each do |cutout|
					h={}
					h[:predicate_id]=cutout.id
					h[:rel_0_count]=0
					h[:rel_1_count]=0
					h[:rel_2_count]=0
					h[:rel_3_count]=0
					h[:rel_4_count]=0

					p_produced=prod.markov_produced_predicates.find :first, :conditions => h
					p_produced=prod.markov_produced_predicates.create(h) if p_produced.blank?
					p_produced.increment :count
					p_produced.save
				end
			end
		end


		def profiles
			@world.objects.select { |o| o.is_a? Profile }
		end

		def initialize
			@empty_queue_callback=nil 	
			@relevance_network=Graph.new
			@objects_to_entities=Hash.new
			@hierachy=Graph.new
			@action_queue=[]
			@processed=Hash.new
			@world=World.instance
			@created_predicates={}
			@main_loop_running=false
			@recalculator=nil
			@action_queue=ActionQueue.new

			@agents_ran=[]
		end

		def on_empty_queue(&block)
			@empty_queue_callback=block 
		end   

		def user_write(object)
			@world.object_of_interest object
		end


		protected

		def calc_relevance(agent, parent, object)
			return 0.9
		end

		def calc_unification(object)
			return 0.9
		end

		def get_next_actions
			highest=0.0
			threshold=options[:search_threshold]
			disabled_agents=options[:disabled_agents]
			relevance_cache={}
			transformer_actions=[]
			actions=[]
			print "!"
			@world.predicates.each do |pred|
				score=0.0
				(Agent.transformer_agents-disabled_agents).each do |agent|
					transformer_actions << [agent,pred] if pred.runnable_by?(agent) and (@processed[agent].nil? or !@processed[agent].include?(pred))
				end
				relevance_cache[pred.subject]=@world.search_relevance(pred) unless relevance_cache.key?(pred.subject)
				search_relevance=relevance_cache[pred.subject]
				next if search_relevance<threshold or search_relevance<highest 
				(Agent.agents-Agent.transformer_agents-disabled_agents).each do |agent|
					if pred.runnable_by?(agent) and (@processed[agent].nil? or !@processed[agent].include?(pred))
						actions << [agent, pred]
					end
				end
			end
			actions.sort! {|a,b| (relevance_cache[a[1].subject].to_f+rand) <=> (relevance_cache[b[1].subject].to_f+rand) }
			actions=transformer_actions+actions
			return actions

		end




	end

end

