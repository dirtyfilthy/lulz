require 'pp'
require 'uri'
require "rexml/document"

module Lulz
	class RapleafSearchAgent < Agent
		#also_accept_on :homepage
		default_process :search
		searcher
		set_description "search rapleaf for email"
		PAGES=2      
		def self.accepts?(pred)
			subject=pred.subject
			object=pred.object
			return false unless Resources.get_rapleaf_api_key
			return false unless object.is_a?(EmailAddress)
			return false if is_processed?(object)
			return true
		end

		def search(pred)
			email=pred.object
			set_processed email

			web=Agent.get_web_agent
			api_key=Resources.get_rapleaf_api_key.api_key
			page=web.get("http://api.rapleaf.com/v2/person/#{email.to_s}?api_key=#{api_key}")
			xml=page.body
			if xml =~ /currently being searched/
				return
			end
			rapleaf_profile=RapleafProfile.new
			rapleaf_profile.email=email

			doc=REXML::Document.new xml			
			brute_fact rapleaf_profile, :email, email
			brute_fact rapleaf_profile, :sex, Sex.new(doc.elements["person/basics/gender"].text) rescue nil
			brute_fact rapleaf_profile, :age, Age.new(doc.elements["person/basics/age"].text) rescue nil
			brute_fact rapleaf_profile, :name, Name.new(doc.elements["person/basics/name"].text) rescue nil
			brute_fact rapleaf_profile, :earliest_activity, doc.elements["person/basics/earliest_known_activity"].text rescue nil
			brute_fact rapleaf_profile, :last_activity, doc.elements["person/basics/latest_known_activity"].text rescue nil
			doc.elements.each("person/basics/occupations/occupation") do |o| 
				oc=o.attributes["job_title"]
				oc=oc+" @ #{o.attributes["company"]}" unless o.attributes["company"].blank?
				brute_fact rapleaf_profile, :occupation, oc
			end
			doc.elements.each("person/basics/universities/university") do |u|
				brute_fact rapleaf_profile, :university, u.text
			end


			doc.elements.each("person/memberships/*/membership") do |membership|
				url=membership.attributes["profile_url"]
				url=URI.parse(url) rescue nil
				next if url.blank?
				brute_fact rapleaf_profile, :homepage_url, url
				brute_fact email, :email_search_result_url, url
			end
		end
	end
end
