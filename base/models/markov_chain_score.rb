module Lulz

   class MarkovChainScore < ActiveRecord::Base
      belongs_to :markov_predicate_chain
      belongs_to :agent, :class_name => "ObjectType"
   
   
   end

end
