require 'pp'
require 'uri'
module Lulz
	class Url2LjUrl < Agent
      transformer
	 set_description "discover livejournal urls"
		PAGES=2
		default_process :transform

		def self.accepts?(pred)
         object=pred.object
			return false unless object.is_a?(URI)
			return false unless object.to_s.downcase=~/livejournal\.com/
			return false if self.is_processed?(object)
         true
		end

		def transform(pred)
         object=pred.object
			journal=object.to_s.downcase.scan(/http:\/\/(.*?)\.livejournal\.com/)
			journal=journal.flatten.first.to_s.gsub("-","_") unless journal.nil?
			if journal=="users"
				journal=object.to_s.downcase.scan(/users\.livejournal\.com\/(.*?)\//)

				journal=journal.flatten.first.to_s
			end
			u=URI.parse("http://users.livejournal.com/#{journal}/profile")
         add_to_world u
         if journal!="community" 
            same_owner object,u
            brute_fact u, :livejournal_url, true
         end
         set_processed object
		end

	end

end
