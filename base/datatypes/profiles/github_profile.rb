module Lulz
   class GithubProfile < Profile
      equality_on :url
      attr_accessor :html_page
   end
end
