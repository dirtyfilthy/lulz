module Lulz

   class MarkovAgentRunProfile < ActiveRecord::Base
      belongs_to :markov_predicate_chain
      belongs_to :agent, :class_name => "ObjectType"
   
   
   end

end
