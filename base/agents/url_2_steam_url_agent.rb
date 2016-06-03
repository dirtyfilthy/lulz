require 'uri'

module Lulz
  class Url2SteamUrl < Agent
    default_process :transform
    transformer
    set_description "discover steam community profile urls"

    # todo: parse URLs in '/profile/<steam id>/' format

    def self.accepts?(pred)
      object = pred.object
      return false unless object.is_a?(URI)
      return false unless object.to_s =~ %r{^https://steamcommunity.com/id/}
      return false if self.is_processed?(object)
      true
    end

    def transform(pred)
      object = pred.object
      user = object.to_s.scan %r{https://steamcommunity.com/id/([a-zA-Z0-9_-]+)}
      user = user.flatten.first.to_s rescue nil
      u = URI.parse("https://steamcommunity.com\/id\/#{user}")
      add_to_world u
      same_owner object, u
      brute_fact u, :is_steam_url, true
      set_processed object
    end

  end
end
