require 'pp'
require 'uri'
module Lulz
	class Url2DiggUrl < Agent
		default_process :transform
		transformer
		set_description "discover digg urls"
		def self.accepts?(pred)
         object=pred.object
			return false unless object.is_a?(URI)
			return false unless object.to_s=~/^http:\/\/digg\.com\/users\/[a-z0-9]+/
			return false if self.is_processed?(object)
         		true
		end

		def transform(pred)
         object=pred.object
			user=object.to_s.scan(/http:\/\/digg.com\/users\/([a-z0-9]+)/)
         user=user.flatten.first.to_s rescue nil
			u=URI.parse("http://digg.com/users/#{user}/")
         same_owner object,u 
         brute_fact u, :is_digg_url, true
         set_processed object
		end

	end

end
