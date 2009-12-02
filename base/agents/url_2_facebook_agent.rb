require 'pp'
require 'uri'
module Lulz
	class Url2FacebookUrl < Agent
		default_process :transform
		transformer
		set_description "discover facebook urls"
		def self.accepts?(pred)
			object=pred.object
			return false unless object.is_a?(URI)
			return false unless object.to_s=~/^http:\/\/www\.facebook.com\/[a-zA-Z-_]+/
				return false if self.is_processed?(object)
			true
		end

		def transform(pred)
			object=pred.object
			brute_fact u, :is_facebook_url, true
			set_processed object
		end

	end

end
