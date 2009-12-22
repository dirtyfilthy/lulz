
module Lulz
	class LinkedinParserAgent < Agent

		default_process :process
		parser
		set_description "parse linkedin profiles"
		def self.accepts?(pred)
			object=pred.subject
			return (object.is_a?(URI::HTTP) and object._query_object(:first, :predicate => :is_linkedin_url) and not is_processed?(object))
		end


		# TODO grab the rest of the data

		def process(pred)

			url=pred.subject
			set_processed url
			web=Agent.get_web_agent
			page=web.get(url)
			html=page.root.to_html
			id=html.scan(/http:\/\/www\.linkedin\.com\/ppl\/webprofile.*?id=(\d+)/).first.first rescue nil
			linkedin_profile=LinkedinProfile.new
			linkedin_profile.url=url
			linkedin_profile.user_id=id
			linkedin_profile.html_page=html
			industry=html.scan(/<dt>Industry<\/dt>.*?<dd>(.*?)<\/dd>/m).first.first.strip rescue nil
			brute_fact linkedin_profile, :profile_url, url
			brute_fact linkedin_profile, :industry, industry	
			page.root.css(".websites li a").each do |a|
				homepage=URI.parse(a.attributes["href"].to_s) rescue nil 
				brute_fact linkedin_profile, :homepage_url, homepage 
			end

			return
		end
	end

end

