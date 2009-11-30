module Lulz
   class XtubeProfile < Profile
      equality_on :username
      attr_accessor :url
      attr_accessor :html_page
   end
end
