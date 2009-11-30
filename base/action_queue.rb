require "#{LULZ_DIR}/lib/algorithms.rb"
module Lulz
	class ActionQueue
		

		def initialize
			@list=[]
			@keys={}
			block ||= lambda { |x, y| (x <=> y) == 1 }
			@heap = Containers::Heap.new(&block)
			@mutex=Mutex.new
			@dirty_preds=[]
			@score_cache={}
			@rel_cache={}
		end

		def add_dirty_predicate(pred)
			@mutex.synchronize {
				@dirty_preds.push(pred) unless @dirty_preds.include?(pred)
			}
		end


		def add_dirty_predicates(predz)
			@mutex.synchronize {
				@dirty_preds=@dirty_preds + predz
				@dirty_preds.uniq!
			}
		end

		def process_dirty_predicates
			t=Time.now
			Blackboard.instance.status("!")
			dirty_copy=nil
			@mutex.synchronize {
				dirty_copy=@dirty_preds.clone
				@dirty_preds=[]
			}

			@rel_cache={}
			to_add=[]
			return if dirty_copy.empty?
			agents=Agent.agents-Agent.transformer_agents-Blackboard.instance.options[:disabled_agents]
			st=0.0
			ht=0.0
			dirty_copy.each do |pred|
				
				next if pred.nil?
				
				agents.each do |agent|
					key=[agent,pred]
					s=Time.now	
					score=self.score(agent,pred) if score.nil?
					st=st+(Time.now-s)
					s=Time.now
					if score<0
						@keys.delete(key)
					elsif pred.runnable_by?(agent)
						@keys[key]=[score, rand,key]
					end
					ht=ht+(Time.now-s)
				end
			end
		   s=Time.now
			@list=@keys.values.sort.reverse
		end

		def add_for_predicate(pred)
			return if pred.nil?
			to_add=[]
			Agent.agents.each do |agent|
				next if pred.nil? or agent.is_processed?(pred) or agent.transformer? and !agent.accepts?(pred)
				score=self.score(agent,pred) unless agent.transformer?
				to_add << [score, [agent,pred]]
			end
			add_or_set_items(to_add)
		end

		def score(agent,predicate)
			score=nil
			if agent.transformer?
				return -1
			end
			if  agent.parser?
				score=6000
			end
			if score.nil?
				h=MarkovPredicateChain.to_h_without_rel(predicate,true)
				unless @rel_cache.key?(predicate.subject)
					@rel_cache[predicate.subject]=predicate.search_relevance_to_i
				end
				h[:relevance]=@rel_cache[predicate.subject]
				
				@score_cache[h]||={}
				score=@score_cache[h][agent] if @score_cache[h].key?(agent)
				score=-1 if @rel_cache[predicate.subject]<0.2
				sc=predicate.to_chain.markov_chain_scores.find_by_agent_id(ObjectType.cache_find_or_create_by_name(agent.to_s).id) if score.nil?
				score=20 if score.nil? and (sc.nil? or sc.count<20)
				score=sc.score if score.nil?
				@score_cache[h][agent]=score
			end
			score=score+rand(20) if score>0 # jumble things up so everything isn't constantly run in the same order
			return score
			
		end
		
		def length
			return @list.length
		end


		def add_or_set_items(items)
			@mutex.synchronize {
				items.each do |priority,item|
					if priority<0
						@keys.delete(item)
					else 
						@keys[item]=[priority,@keys.keys.length,rand,item]
					end
				end
			}
			@list=@keys.values.sort!
		end

		def add_or_set(priority,item)
				
			@mutex.synchronize {
				if priority<0
					@keys.delete(item)
				else 
					@keys[item]=[priority,@keys.keys.length,rand,item]
				end
				@list=@keys.values.sort!
			}
		end

		def next
			t=Time.now

			process_dirty_predicates if @list.length<30 or @dirty_preds.length>60
			@mutex.synchronize{
				top=nil
				too_many=[]
				while(!@list.empty?)
					ft=@list.shift
					top=ft[2]
					if top[0].too_many_agents?
						top=nil
						too_many << ft
						next
					end
					@keys.delete(top)
					break if top[1].runnable_by?(top[0]) rescue false
				end
				@list=@list+too_many
				return top
			}
		end
	end
end
	
