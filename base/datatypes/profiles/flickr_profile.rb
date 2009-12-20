module Lulz
   class FlickrProfile < Profile
	   equality_on :url
      sub_objects :photo
		attr_accessor :html_page
		properties :user_id
	end
end
