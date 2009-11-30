
module Lulz

   class MarkovPredicateChain < ActiveRecord::Base
      belongs_to :pred_1, :class_name => "MarkovPredicate"
      belongs_to :pred_2, :class_name => "MarkovPredicate"
      DISCOUNT=0.90
      RUNS=5
      REWARD=600
      PROFILE_COST=2
		PROFILE_MULTIPLIER=0.2
		has_many :markov_produced_objects
      has_many :markov_agent_run_profiles
      has_many :markov_chain_scores
		@@old_values=0
      @@cached_score={}      
      @@cached_probabilities={}
      @@cached_immediate_score={}
      @@agents_by_chain_id={}
      @@insta_follow=[]
      def find_predicate_probabilities(agent_id)
	 predz=MarkovProducedPredicate.find_by_sql("select markov_produced_predicates.*, ((select (CAST(markov_agent_run_profiles.ran AS REAL)/markov_agent_run_profiles.tried) FROM markov_agent_run_profiles WHERE markov_agent_run_profiles.markov_predicate_chain_id=#{self.id} AND markov_agent_run_profiles.agent_id=#{agent_id}) * (CAST(markov_produced_predicates.count AS REAL)/(select sum(p2.count) from markov_produced_predicates as p2 where p2.predicate_id=markov_produced_predicates.predicate_id AND p2.markov_produced_object_id=markov_produced_predicates.markov_produced_object_id)) *  (CAST(markov_produced_objects.count AS real)/(SELECT sum(p2.count) FROM \"markov_produced_objects\" AS p2 WHERE markov_produced_objects.markov_predicate_chain_id=p2.markov_predicate_chain_id AND markov_produced_objects.agent_id=p2.agent_id))) as probability FROM markov_predicate_chains LEFT JOIN markov_produced_objects ON markov_produced_objects.markov_predicate_chain_id=markov_predicate_chains.id LEFT JOIN markov_produced_predicates ON markov_produced_predicates.markov_produced_object_id=markov_produced_objects.id WHERE agent_id=#{agent_id} AND markov_predicate_chains.id=#{self.id};")
	 predz.delete(nil)
	 predz
      end

		def self.to_h_without_rel(predicate,new_policy)
					
         h={}
			h[:pred_1_id]=predicate.to_cutout.id
			h[:pred_2_id]=predicate.created_from.last.to_cutout.id rescue nil	
         h[:new_policy]=new_policy
			return h
		end

		def self.to_h(predicate,new_policy)
					
         h={}
			h[:pred_1_id]=predicate.to_cutout.id
			h[:pred_2_id]=predicate.created_from.last.to_cutout.id rescue nil	
         h[:new_policy]=new_policy
		   h[:relevance]=predicate.search_relevance_to_i rescue 0
			return h
		end

      def self.find_predicate_chain(predicate,new_policy)
         h={}
			h[:pred_1_id]=predicate.to_cutout.id
			h[:pred_2_id]=predicate.created_from.last.to_cutout.id rescue nil	
         h[:new_policy]=new_policy
		   h[:relevance]=predicate.search_relevance_to_i rescue 0
         chain=nil
			begin 
				chain=MarkovPredicateChain.find :first, :conditions => h
				chain=MarkovPredicateChain.create(h) if chain.nil?
			rescue SQLite3::BusyException
				sleep 0.1
				retry
			end	
         return chain

      end

      def self.flip_cache!
	 @@old_values=(@@old_values+1)%2
      end

      def self.get_immediate_score(chain_id,agent_id,reward)
	 @@cached_immediate_score[chain_id]||={}
	 return @@cached_immediate_score[chain_id][agent_id] if @@cached_immediate_score[chain_id].key?(agent_id)
	 score=0
	 chain=MarkovPredicateChain.find_by_id chain_id
	 objects=chain.markov_produced_objects.find :all, :select => ' *,(CAST(count AS real)/(SELECT sum(p2.count) FROM "markov_produced_objects" AS p2 WHERE markov_produced_objects.markov_predicate_chain_id=p2.markov_predicate_chain_id AND markov_produced_objects.agent_id=p2.agent_id)) as probability', :conditions => ['agent_id = ?', agent_id]
	 objects.each do |obj|
	    score=score+(((obj.matches*reward)-(obj.markov_agent_time.avg_time+(obj.profiles.to_i*(PROFILE_COST+(obj.profiles.to_i*PROFILE_MULTIPLIER)))))*obj.probability.to_f)
	 end
	 @@cached_immediate_score[chain_id][agent_id]=score
	 return score
      end

	 


      def self.get_cached_score(chain_id,agent_id)
	 @@cached_score[@@old_values]||={}
	 @@cached_score[@@old_values][chain_id]||={}
	 return 0.0 if @@cached_score[@@old_values][chain_id][agent_id].blank?
	 return @@cached_score[@@old_values][chain_id][agent_id]
      end

      def self.store_cached_score(chain_id,agent_id,score)
	 new_values=(@@old_values + 1) % 2
	 @@cached_score||={}
	 @@cached_score[new_values]||={}
	 
	 @@cached_score[new_values][chain_id]||={}
	 @@cached_score[new_values][chain_id][agent_id]=score

      end

      def agents
      	 self.markov_produced_objects.map{ |o| o.agent}.uniq
      end

      def unshift(markov_pred,relevance)
		h={}
			h[:pred_2_id]=self[:pred_1_id]
		h[:pred_1_id]=markov_pred.id
	 h[:relevance]=relevance
	 h[:new_policy]=self.new_policy
	 chain=MarkovPredicateChain.find :first, :conditions => h
	 chain=MarkovPredicateChain.create(h) if chain.nil?
	 return chain
      end


      def monte_carlo(agent)
         results={}
	 produced=markov_produced_objects.find :first, :conditions => ['agent = ?', agent], :order => "count * RANDOM() DESC"
	 results[:matches]=produced.matches
	 
	 time=produced.markov_agent_time.avg_time  
   	 results[:time]=time
	 results[:predicates]=[]
	 results[:agent]=agent
	 cutoutz=produced.markov_produced_predicates.map{|p| p.predicate}
	 cutoutz.each do |cutout|
	    predz=produced.markov_produced_predicates.find :first, :conditions => ['pred = ?', cutout], :order => 'count * RANDOM() DESC'
	    0.upto(4){|r| results[:predicates] << ([{:predicate => cutout, :relevance => r }]*predz["rel_#{r}".to_sym])}
	 end	 
      	 results[:predicates].flatten!
	 results
      end

      def self.chain_will_follow?(chain_id,agent_id)
         return true if @@insta_follow.include?(agent_id)
	 return (MarkovPredicateChain.get_cached_score(chain_id,agent_id)>0.0)
      end

      def self.get_agent_ids(chain_id)
      	return @@agents_by_chain_id[chain_id] unless @@agents_by_chain_id[chain_id].nil?
	chain=MarkovPredicateChain.find_by_id chain_id
	agent_ids=chain.agents.map{|a| a.id}
	@@agents_by_chain_id[chain_id]=agent_ids
	return agent_ids
      end

      def get_predicate_probabilities(agent_id)
	 @@cached_probabilities[self.id]||={}
	 
	 return @@cached_probabilities[self.id][agent_id] if @@cached_probabilities[self.id].key?(agent_id)
	 predicates=self.find_predicate_probabilities(agent_id) 
	 
	 @@cached_probabilities[self.id][agent_id]={}


	 predicates.each do |pred|
	    @@cached_probabilities[self.id][agent_id][[pred.id,pred.probability.to_f]]||={}
	    next if pred.predicate.nil?
	    0.upto(4).each do |rel|
	       chain=self.unshift(pred.predicate, rel)
	       @@cached_probabilities[self.id][agent_id][[pred.id,pred.probability.to_f]][chain.id]=pred["rel_#{rel}_count"]
			
		 end
	 end
	 return @@cached_probabilities[self.id][agent_id]
      end

      def score(agent_id,discount,reward)
	 score=MarkovPredicateChain.get_immediate_score(self.id,agent_id,reward)
	 probs=get_predicate_probabilities(agent_id)
	 sum={}
	 probs.each do |pred,chains|
	    pred_score=0
	    chains.each do |chain_id,count|
	       chain_score=0

	       MarkovPredicateChain.get_agent_ids(chain_id).each do |agent_id|
		  next unless MarkovPredicateChain.chain_will_follow?(chain_id,agent_id)
		  chain_score=chain_score+MarkovPredicateChain.get_cached_score(chain_id,agent_id)*count
		  puts "chainscore #{chain_score}"
	       end
	       pred_score=pred_score+chain_score
	    end

	    
	    delta=(discount*pred[1].to_f*pred_score)
	    puts "delta #{delta} pred_score #{pred_score}"
	    score=score+delta
	 end
	 return score
      end

      def get_immediate_score(agent,reward)
      	return MarkovPredicateChain.get_immediate_score(self.id,agent.id,reward)
      end
	         
	       


      def self.run_stochastic
	 
      @@insta_follow=Agent.transformer_agents+Agent.parser_agents
      @@insta_follow.map!{|a| ObjectType.find_by_name(a.to_s)}
      @@insta_follow.delete(nil)
      @@insta_follow.map!{|a| a.id}
      puts @@insta_follow.join(",")
	 MarkovPredicateChain.transaction {
		chains=MarkovPredicateChain.find :all
	 puts "Building predicate probabilities for #{chains.length} chains"
	 index=0
	 chains.each do |chain|
		 chain.agents.each do |agent|
			 chain.get_predicate_probabilities(agent.id)
			 chain.get_immediate_score(agent,REWARD)
			 index=index+1
			 puts index
		 
		 end
	 end
	 0.upto(10) do |iteration|
	    chains.each do |chain|
	       MarkovPredicateChain.get_agent_ids(chain.id).each do |agent_id|
		  
		  puts "Iteration #{iteration}"
		  score=chain.score(agent_id,DISCOUNT,REWARD)
		  MarkovPredicateChain.store_cached_score(chain.id,agent_id,score)
	       end
	    end
	    MarkovPredicateChain.flip_cache! 
	 end
		chains.each do |chain|
			MarkovPredicateChain.get_agent_ids(chain.id).each do |agent_id|
				chain_score=chain.markov_chain_scores.find_or_create_by_agent_id agent_id
				chain_score.score=MarkovPredicateChain.get_cached_score(chain.id,agent_id)
				chain_score.count=chain.markov_produced_objects.sum(:count, :conditions => {:agent_id => agent_id})
				chain_score.save
			end
		end
	 }
      end
    


   end

end
