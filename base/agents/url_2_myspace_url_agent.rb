require 'pp'
require 'uri'
module Lulz
	class Url2MyspaceUrlAgent < Agent
		default_process :transform
      transformer
	 set_description "discover myspace urls"
		def self.accepts?(pred)
         object=pred.object
	      	
			return false unless object.is_a?(URI)
         return false unless object.to_s=~/http:\/\/www.myspace.com\/[a-z0-9]+/ or object.to_s=~/.*myspace\.com.*fuseaction=user\.viewProfile/i
			return false if self.is_processed?(object)
         true
		end

		def transform(pred)
         object=pred.object
         
         brute_fact object, :is_myspace_url, true
         set_processed object
		end

	end

end
