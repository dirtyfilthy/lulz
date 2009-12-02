
module Lulz
	class IdenticaParserAgent < Agent
		default_process :process
		parser
		set_description "parse identica profiles"
		def self.accepts?(pred)

			object=pred.subject
			return false unless object.is_a?(URI)
			return false unless object._query_object(:first, :predicate => :is_identica_url)
			return false if is_processed?(object)
			return true

		end


		# TODO grab the rest of the data

		def process(pred)

			url=pred.subject

			set_processed url
			web=Agent.get_web_agent
			page=web.get(url)
			html=page.root.to_html

			identica_profile=IdenticaProfile.new
			identica_profile.url=url
			identica_profile.html_page=html
			brute_fact identica_profile, :profile_url, url
			c=Country.new(page.root.css(".entity_location .label").first.text) rescue nil
			if c.blank?
				c=Country.new(page.root.css(".entity_location .label").first.text.split(",")[1]) rescue nil
			end
			homepage_url=URI.parse(page.root.css(".entity_url .url").first.text) rescue nil 
			picture_url=URI.parse(page.root.css(".avatar").first.attributes["src"].to_s) rescue nil
			lo=page.root.css(".entity_location .label").first.text.split(",")[0] rescue nil
			tmp_c=Country.new(lo)
			if tmp_c.blank?
				lo=Locality.new(lo)
			else
				lo=nil
			end

			single_fact identica_profile, :country, c
			single_fact identica_profile, :city, lo
			single_fact identica_profile, :homepage_url, homepage_url
			single_fact identica_profile, :picture, picture_url


			# let the hcard parser take care of the rest
			return
		end
	end

end

