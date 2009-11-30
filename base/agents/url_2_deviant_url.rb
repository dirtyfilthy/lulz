require 'pp'
require 'uri'
module Lulz
	class Url2DeviantUrl < Agent
		PAGES=2
		default_process :transform
      transformer
	 set_description "discover deviantart urls"
		def self.accepts?(pred)
         object=pred.object
			return false unless object.is_a?(URI)
			return false unless object.to_s.downcase=~/\.deviantart\.com/ and not (object.to_s.downcase=~/sitedossier\.com/)
			return false if self.is_processed?(object)
         true
		end

		def transform(pred)
         object=pred.object
			user=object.to_s.downcase.scan(/http:\/\/(.*?)\.deviantart\.com/)
         user=user.flatten.first.to_s.gsub(/^www\./,"")
			u=URI.parse("http://#{user}.deviantart.com/")
         add_to_world u
         
         brute_fact u, :deviant_art_url, true
	 same_owner u,object unless u==object
         set_processed object
		end

	end

end
