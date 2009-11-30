require 'pp'
require 'uri'
module Lulz
	class Url2BlogspotUrlAgent < Agent
		default_process :transform
      transformer
	    set_description "discover blogspot urls"
		def self.accepts?(pred)
         object=pred.object
	      	
			return false unless object.is_a?(URI)
         return false unless object.to_s=~/^http:\/\/[a-z0-9-]+.blogspot.com/ 
			return false if self.is_processed?(object)
         true
		end

		def transform(pred)
         object=pred.object
         name=object.to_s.scan(/^http:\/\/([a-z0-9-]+).blogspot.com/).first.first rescue nil
         url=URI.parse("http://#{name}.blogspot.com/")
         same_owner url,object
         brute_fact url, :is_blogspot_url, true
         set_processed object
		end

	end

end
