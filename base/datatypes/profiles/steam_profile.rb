module Lulz
  class SteamProfile < Profile
    equality_on :url
    attr_accessor :html_page
  end
end
