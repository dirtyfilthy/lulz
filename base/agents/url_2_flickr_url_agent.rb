require 'pp'
require 'uri'
module Lulz
	class Url2FlickrUrl < Agent
		default_process :transform
      transformer
	 set_description "discover flickr urls"
		def self.accepts?(pred)
         object=pred.object
			return false unless object.is_a?(URI)
			return false unless object.to_s=~/^http:\/\/www\.flickr\.com\/[a-z]+\/.*?\//
			return false if self.is_processed?(object)
         true
		end

		def transform(pred)
         object=pred.object
			user=object.to_s.scan(/http:\/\/www.flickr.com\/[a-z]+\/(.*?)\//)
         user=user.flatten.first.to_s rescue nil
			u=URI.parse("http://www.flickr.com/people/#{user}/")
         add_to_world u
         same_owner object, u 
         brute_fact u, :is_flickr_url, true
         set_processed object
		end

	end

end
