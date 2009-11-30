module Lulz
   class BlogspotProfile < Profile
	   equality_on :member_id
      attr_accessor :url
      attr_accessor :html_page
   
      def to_s
	 return url
      end
   end
end
