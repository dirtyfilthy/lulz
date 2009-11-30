require 'pp'
require 'uri'
module Lulz
	class BlogspotUrl2BlogspotProfileUrlAgent < Agent
		default_process :process
		parser
		set_description "search a blogspot for the profile url"
		def self.accepts?(pred)

         object=pred.object
	      	
			return false unless object.is_a?(URI)
         return false unless object._query_object(:first, :predicate => :is_blogspot_url) 
			return false if object._query_object(:first, :predicate => :blogspot_profile_url)
         return false if self.is_processed?(object)
         true
		end

		def process(pred)
         object=pred.object
         agent=Agent.get_web_agent
         page=agent.get(object)
         url=URI.parse(page.root.css("link[rel='me']").first.attributes["href"].to_s) rescue nil
         brute_fact object, :blogspot_profile_url, url 
         brute_fact url, :is_blogspot_profile_url, true
         set_processed object
		end

	end

end
