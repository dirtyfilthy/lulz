require 'pp'
module Lulz
   class ExpanderAgent < Agent
      set_description "expander agent"		
	 def self.accepts?(object)
	    false
	 end

       def expand(url)
          pred1=brute_fact url, :is_expandable_url, true
	  pred2=brute_fact url, :as_object, url
	  pred1.expand
	  pred2.expand
          
      end
	
   end

end
