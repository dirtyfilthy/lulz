require 'pp'
require 'uri'
module Lulz
	class Url2BeboUrlAgent < Agent
		default_process :transform
      transformer
	 set_description "discover bebo urls"
		def self.accepts?(pred)
         object=pred.object
			return false unless object.is_a?(URI)
			return false unless object.to_s=~/http:\/\/www.bebo.com\/Profile\.jsp\?MemberId=/
			return false if self.is_processed?(object)
         true
		end

		def transform(pred)
         object=pred.object
 
         brute_fact object, :is_bebo_url, true
         set_processed object
		end

	end

end
