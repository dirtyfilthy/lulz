module Lulz

   class MarkovAgentTime < ActiveRecord::Base
      belongs_to :markov_predicate_object
   
      def avg_time
         total_time/ran.to_f
      end
   
   end

end
