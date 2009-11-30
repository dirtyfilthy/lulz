module Lulz
   class LinkedinProfile < Profile
	   equality_on :user_id
      def to_s
	 return url.to_s
      end
	   
      attr_accessor :url
      attr_accessor :html_page
   end
end
