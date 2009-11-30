require 'pp'
require 'uri'
module Lulz
	class Url2LastfmUrl < Agent
		default_process :transform
      transformer
	 set_description "discover last fm urls"
		def self.accepts?(pred)
         object=pred.object
			return false unless object.is_a?(URI)
			return false unless object.to_s=~/^http:\/\/www\.last\.fm\/user\/[A-Za-z0-9_-]+/
			return false if self.is_processed?(object)
         true
		end

		def transform(pred)
         object=pred.object
			user=object.to_s.scan(/http:\/\/www\.last\.fm\/user\/([A-Za-z0-9_-]+)/)
         user=user.flatten.first.to_s.downcase rescue nil
			u=URI.parse("http://www.last.fm/user/#{user}")
         brute_fact u, :is_lastfm_url, true
        same_owner object,u 
	set_processed object
      set_processed u
		end

	end

end
