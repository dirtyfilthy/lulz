require 'pp'
require 'uri'
module Lulz
	class Url2IdenticaUrlAgent < Agent
		default_process :transform
	       transformer
	       set_description "discover identica urls"
		def self.accepts?(pred)
         object=pred.object
			return false unless object.is_a?(URI)
			return false unless object.to_s=~/^http:\/\/identi\.ca\/[a-z0-9_-]+/
			return false if self.is_processed?(object)
         true
		end

		def transform(pred)
         object=pred.object
			user=object.to_s.scan(/http:\/\/identi.ca\/([a-z0-9_-]+)/)
         user=user.flatten.first.to_s rescue nil
			u=URI.parse("http://identi.ca/#{user}/")
         brute_fact u, :is_identica_url, true
        same_owner object,u 
	set_processed object
		end

	end

end
