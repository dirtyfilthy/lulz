module Lulz
	class Agent

		attr_reader :produced_predicates
		attr_accessor :produced_matches
		attr_reader :from_predicate
		attr_reader :status
		@@agents=[]
		@@transformer_agents=[]
		@@searcher_agents=[]
		@@parser_agents=[]
		@@recalc_queue=[]
		@@personal_info_mutex=Mutex.new	
		@@running_agents={}
		@@process_mutex=Mutex.new
		
		def initialize(world)
			self._world=world
			@produced_predicates=[]
			@produced_matches=0
			@start_time=nil
			@end_time=nil
			@status="N"
		end

		def set_clique(pred1,pred2)
			Predicate.set_clique(pred1,pred2)
		end	

		def self.running_agents
			stopped=@@running_agents.keys.select { |agent| 
				dead=!@@running_agents[agent].alive? rescue true
				dead
			}
			stopped.each { |dead| @@running_agents.delete(dead) }
			return @@running_agents
		end

		def self.list_agents
			self.running_agents.keys.each do |a| 

				puts "#{a.status} #{a.class.to_s} (#{a.time_running_secs} secs)"
			end
		end

		def self.recalc_queue
			return @@recalc_queue
		end

		def self.run_inline(pred)
			a=self.new(World.instance)
			p=pred
				a.set_processed(pred)
				begin
					Blackboard.instance.status_agent(self)
					STDOUT.flush
					a.run(p)
				rescue Exception => e
					ERROR_LOG.error e
					ERROR_LOG.error e.backtrace.join("\n")
				end 
				a.process_predicates
				b=Blackboard.instance
				b.agents_ran<<a
				b.created_predicates[p]||=[]
				b.created_predicates[p]<<a

		end
		def self.run(pred)
			agent=self.new(World.instance)
			
			agent.set_processed(pred)
			
			thread=Thread.new(agent,pred) { |a,p|
				
				Thread.abort_on_exception=true
				
				begin
					Blackboard.instance.status_agent(self)
					STDOUT.flush
					a.run(p)
				rescue Exception => e
					ERROR_LOG.error e
					ERROR_LOG.error e.backtrace.join("\n")
				end 
				a.process_predicates
				b=Blackboard.instance
				b.agents_ran<<a
				b.created_predicates[p]||=[]
				b.created_predicates[p]<<a
				@@running_agents.delete(a)
				ActiveRecord::Base.clear_active_connections!
			}

			@@running_agents[agent]=thread
			thread.priority=1
		end


		def self.too_many_agents?
			return (self.one_at_a_time? and Agent.running_agents.keys.map{ |a| a.class }.include?(self))
		end

		def run(pred)
			@status="R"
			@from_predicate=pred
			@start_time=Time.now
			@from_predicate.ran_by << self
			exception=nil
			begin
				process(@from_predicate)
			rescue Exception => e
				exception=e
			ensure
				finish
				raise exception unless exception.blank?
			end

		end

		def self.description
			return ""
		end

		def finish
			@end_time=Time.now
		end

		def time_running_secs
			return 0 if @start_time.nil?
			return Time.now.to_i-@start_time.to_i
		end

		def time_ran
			@end_time.to_f-@start_time.to_f
		end

		def self.one_at_a_time?
			false
		end

		def self.transformer?
			false
		end

		def self.searcher?
			false
		end

		def self.parser?
			false
		end


		def self.personal_info_mutex
			@@personal_info_mutex
		end



		def set_processed(object)
			self._world.set_processed(self.class, object)
		end

		def list_processed
			self._world.list_processed(self.class)
		end

		def is_processed?(object)
			return Agent.is_processed?(object)
		end

		def self.is_processed?(object)
			return (World.instance.is_processed?(self, object))
		end      

		def add_to_world(object)

			self._world.add object 
		end

		def normalize(obj)
			self._world.normalize_object(obj)

		end

		def predicate(subject,predicate,object,probability,type)
			subject=normalize(subject)
			object=normalize(object)
			@produced_predicatez << subject._predicate(:object => object, :name => predicate, :probability => probability, :creator => self, :type=> type)
		end

		def predicate_exists?(subject,name)
			return (not subject._query_object(:first, :predicate => name).blank?)
		end


		def brute_fact(subject,predicate,object)
			subject=normalize(subject)
			object=normalize(object)
			pred=subject._predicate(:object => object, :name => predicate, :probability => P_TRUE, :creator => self, :type => :brute_fact)
			@produced_predicates << pred unless pred.nil?

			return pred
		end

		def brute_fact_once(subject,predicate,object)
			subject=normalize(subject)
			object=normalize(object)

			return nil if predicate_exists?(subject,predicate)
			pred=brute_fact(subject,predicate,object)
			return pred
		end

		def single_fact_once(subject,predicate,object)
			subject=normalize(subject)
			object=normalize(object)


			return nil if predicate_exists?(subject,predicate)
			single_fact(subject,predicate,object)
		end

		def brute_inference_once(subject,predicate,object)
			subject=normalize(subject)
			object=normalize(object)

			return nil if predicate_exists?(subject,predicate)
			brute_inference(subject,predicate,object)
		end



		def single_fact(subject,predicate,object)
			subject=normalize(subject)
			object=normalize(object)


			pred=subject._predicate(:object => object, :name => predicate, :probability => P_TRUE, :creator => self, :type => :single_fact)
			@produced_predicates << pred unless pred.nil?
			return pred

		end
		


		def brute_inference(subject,predicate,object)
			subject=normalize(subject)
			object=normalize(object)


			pred=subject._predicate(:object => object, :name => predicate, :probability => P_TRUE, :creator => self, :type => :brute_inference)
			@produced_predicates << pred unless pred.nil?
			return pred

		end

		def self.enqueue_recalc(profile)
			@@personal_info_mutex.synchronize {
				@@recalc_queue.push(profile) unless @@recalc_queue.include?(profile)
			}
		end

		def self.process_recalc_queue
			loop do
				profile=nil
				@@personal_info_mutex.synchronize {
					profile=@@recalc_queue.first

				}
				if profile.nil?
					STDOUT.flush
					sleep 2
					next
				end
				
				Blackboard.instance.status("?")
				STDOUT.flush
				begin		
					t=Time.now	
					World.instance.recalc_matches(profile)
					
				rescue Exception => e
					puts e
					puts e.backtrace.join("\n")
				end
				sleep 1 unless Agent.running_agents.keys.empty?	
				@@personal_info_mutex.synchronize {
					@@recalc_queue.shift
				}
			end
		end

		def process_predicates
			@status="P"
			changed_profiles={}

				t=Time.now
				@produced_predicates.uniq!
				@last_profile_object=@from_predicate.last_profile_object rescue nil
				@last_search_agent=@from_predicate.last_search_agent rescue nil
				@last_search_agent=self if self.class.searcher?
				if(!@from_predicate.nil? and @from_predicate.subject.is_a? Profile)
					@last_profile_object=@from_predicate.object

				end

				@produced_predicates.each do |pred|
					next if pred.nil?
					pred.created_from=@from_predicate.created_from.clone.push(@from_predicate) unless @from_predicate.nil?
					pred.last_profile_object=@last_profile_object
					pred.last_search_agent=@last_search_agent
					pred.to_cutout
					if pred.subject.is_a? Profile 
						profile=pred.subject
						changed_profiles[profile]||=[]
						changed_profiles[profile]<<pred
					end
					Agent.transformer_agents.each do |ag|
								
						ag.run_inline(pred) if pred.runnable_by?(ag)
					end
					Blackboard.instance.action_queue.add_dirty_predicate(pred)
				end
				changed_profiles.keys.each do |profile|
					cliqable={}
					
					# autoclique countries, localities and single_facts
					
					profile._predicates.each do |pred|
						key=nil
						key=:countries if pred.object.is_a?(Country) or pred.object.is_a?(Locality)
						key=pred.relationship if pred.type==:single_fact
						cliqable[key] ||= [] unless key.nil?
						cliqable[key] << pred unless key.nil?
					end
					cliqable.each_value {|clique|
						top=clique.pop
						clique.each {|c| set_clique top,c } unless top.nil?
					}
						Agent.enqueue_recalc(profile)
				end
		end




		def same_owner(a, b)
			a1=normalize(a)
			b1=normalize(b)
			return nil if a1==b1
			brute_inference a, :same_owner, b
			brute_inference b, :same_owner, a

		end

		def self.inherited(subclass)
			agents << subclass
			transformer_agents.push(subclass).uniq! if subclass.transformer?
			searcher_agents.push(subclass).uniq! if subclass.searcher?
			parser_agents.push(subclass).uniq! if subclass.parser?
		end	

		def self.agents
			@@agents
		end

		def self.transformer_agents
			@@transformer_agents
		end

		def self.searcher_agents
			@@searcher_agents
		end

		def self.parser_agents
			@@parser_agents
		end


		def self.get_web_agent()
			agent= WWW::Mechanize.new
			#agent.set_proxy("localhost",3128)
			return agent
		end


		def process(o)
			results=[]
			results=self.send(self.class.default_process_method,o) unless self.class.default_process_method.nil?
			return results
		end


		def trigger!(h)
			h.each do |k,v|
				agent=k.new(self._world)
				agent.process(v)
			end
		end


		def trigger(h)
			h.each do |k,v|
				if k.accepts?(v)
					agent=k.new(self._world)
					agent.process(v)
				end
			end
		end



		def self.default_process_method()
			nil
		end

		def self.default_process_method()
			nil
		end


		def self.acceptable_object_methods()
			[]
		end


		def self.accept_if_object_method(method, options=[])

			acceptable_methods=self.acceptable_object_methods << method

			class_eval %{
				def self.acceptable_object_methods()
				#{acceptable_methods.inspect}
				end
			}
		end

		def self.acceptable_subject_methods()
			[]
		end

		def self.set_description(desc)
			class_eval %{
				def self.description
					"#{desc}"
		end

			} 
		end

		def self.one_at_a_time
			class_eval %{
				def self.one_at_a_time?
					true
				end
			}	
		end

		def self.transformer
			class_eval %{
				def self.transformer?
					true
				end

			}
			@@transformer_agents.push(self).uniq!
	end

		def self.searcher
			class_eval %{
				def self.searcher?
					true
				end

			}
			@@searcher_agents.push(self).uniq!
		end


		def self.parser
			class_eval %{
				def self.parser?
					true
				end

			}
			@@parser_agents.push(self).uniq!
		end



		def self.accept_if_subject_method(method, options=[])

			acceptable_methods=self.acceptable_subject_methods << method

			class_eval %{
				def self.acceptable_subject_methods()
				#{acceptable_methods.inspect}
				end
			}
		end




		def self.accepts?(predicate)
			acceptable_object_methods.each do |method|
				return true if predicate.object.respond_to?(method) and !self.is_processed?(predicate.object)
			end
			acceptable_subject_methods.each do |method|
				return true if predicate.subject.respond_to?(method) and !self.is_processed?(predicate.subject)
			end

			return false
		end

		def self.default_process(method)
			define_attr_method :default_process_method, method
		end

		def self.singleton_class
			class << self; self; end
		end



		def self.define_attr_method(name, value)
			singleton_class.send :alias_method, "original_#{name}", name
			singleton_class.class_eval do
				define_method(name) do
					value
				end
			end
		end

	end
end
