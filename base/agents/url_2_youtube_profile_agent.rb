require 'pp'
require 'uri'
module Lulz
	class Url2YouTubeProfileAgent < Agent
		default_process :transform
      transformer
	 set_description "discover youtube urls"
		def self.accepts?(pred)
         object=pred.object

			return false unless object.is_a?(URI)
         return false unless object.to_s.downcase=~/^http:\/\/www\.youtube\.com\/user\//
         return false if self.is_processed?(object)
         true
		end

		def transform(pred)
				
         u=pred.object
         set_processed u
			user=u.to_s.downcase=~/^http:\/\/www\.youtube\.com\/user\/([a-zA-Z0-9_-]+)/
			user=user.first.first.to_s.downcase rescue nil
			return if user.nil?
			url=URI.parse("http://www.youtube.com/user/#{user}") 
			same_object u,url
         brute_fact url, :youtube_profile_url, true
		end

	end

end
