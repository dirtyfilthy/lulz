require 'pp'
require 'uri'
module Lulz
	class Url2BlogspotProfileUrlAgent < Agent
		default_process :transform
      transformer
	    set_description "discover blogspot profile url "
		def self.accepts?(pred)
         object=pred.object
	      	
			return false unless object.is_a?(URI)
         return false unless object.to_s=~/^http:\/\/www\.blogger\.com\/profile\/\d+/ 
			return false if self.is_processed?(object)
         true
		end

		def transform(pred)
         object=pred.object
         id=object.to_s.scan(/^http:\/\/www\.blogger\.com\/profile\/(\d+)/).first.first rescue nil
         url=URI.parse("http://www.blogger.com/profile/#{id}")
	 same_owner url,object
	 brute_fact url, :is_blogspot_profile_url, true
         set_processed object
	 set_processed url
		end

	end

end
