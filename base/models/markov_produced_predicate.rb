module Lulz

   class MarkovProducedPredicate < ActiveRecord::Base
      belongs_to :markov_produced_object
      belongs_to :predicate, :class_name => "MarkovPredicate"



   end

end
