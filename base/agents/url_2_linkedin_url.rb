require 'pp'
require 'uri'
module Lulz
	class Url2LinkedinUrl < Agent
		default_process :transform
      transformer
	       set_description "discover linked in urls"
		def self.accepts?(pred)
         object=pred.object
			return false unless object.is_a?(URI)
			return false unless object.to_s=~/^http:\/\/.*?\.linkedin\.com\/in\// or object.to_s=~/^http:\/\/.*?\.linkedin\.com\/pub\//
			return false if self.is_processed?(object)
         true
		end

		def transform(pred)
         u=pred.object
         add_to_world u
         brute_fact u, :is_linkedin_url, true
         set_processed u
		end

	end

end
