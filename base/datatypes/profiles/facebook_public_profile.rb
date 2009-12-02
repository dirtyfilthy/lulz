module Lulz
   class FacebookPublicProfile < Profile
	   attr_accessor :html_page
	   equality_on :url
   end
end
