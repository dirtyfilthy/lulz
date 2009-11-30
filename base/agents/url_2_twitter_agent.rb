require 'pp'
require 'uri'
module Lulz
	class Url2TwitterUrl < Agent
		default_process :transform
	       transformer
		set_description "discover twitter urls"
		def self.accepts?(pred)
         object=pred.object
			return false unless object.is_a?(URI)
			return false unless object.to_s=~/twitter\.com\/[A-Za-z0-9_-]+/
			return false if self.is_processed?(object)
         true
		end

		def transform(pred)
         object=pred.object
			user=object.to_s.scan(/twitter.com\/([A-Za-z0-9_-]+)/)
         user=user.flatten.first.to_s.downcase rescue nil
			u=URI.parse("http://twitter.com/#{user}/")
         brute_fact u, :is_twitter_url, true unless user.nil?
        same_owner object,u  unless user.nil?
	set_processed object
		end

	end

end
