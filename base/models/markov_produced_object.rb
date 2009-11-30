module Lulz

   class MarkovProducedObject < ActiveRecord::Base
      belongs_to :markov_predicate_chain
      has_one :markov_agent_time
      has_many :markov_produced_predicates
      belongs_to :agent, :class_name => "ObjectType"      
      @predicates_with_probabilities=nil
      
      def find_markov_produced_predicates_with_probabilities
	 return @predicates_with_probabilities unless @predicates_with_probabilities.nil?
	 @predicates_with_probabilities=self.markov_produced_predicates.find :all, :select => "*,(CAST(count AS REAL)/(select sum(p2.count) from markov_produced_predicates as p2 where p2.predicate_id=markov_produced_predicates.predicate_id AND p2.markov_produced_object_id=markov_produced_predicates.markov_produced_object_id)) as probability"
	 return @predicates_with_probabilities
      end

   
   end

end
