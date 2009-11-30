module Lulz
   class LinkedinDirectoryProfile < Profile
	   equality_on :linkedin_url
   
	   def to_s
	     return linkedin_url
	   end
   
   end



end
