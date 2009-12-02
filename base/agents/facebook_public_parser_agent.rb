
module Lulz
	class FacebookPublicAgent < Agent
		default_process :process
		parser
		set_description "parse facebook profiles"
		def self.accepts?(pred)

			object=pred.subject
			return false unless object.is_a?(URI)
			return false unless object._query_object(:first, :predicate => :is_facebook_url)
			return false if is_processed?(object)
			return true

		end



		def process(pred)

			url=pred.subject

			set_processed url
			web=Agent.get_web_agent
			page=web.get(url)
			html=page.body
			canonical=URI.parse(html.scan(/<link rel="canonical" href="(.*?)"/).first.first) rescue nil
			return nil if canonical.nil?
			facebook_public=FacebookPublicProfile.new
			facebook_public.url=canonical
			facebook_public.html_page=html
			brute_fact facebook_public, :profile_url, canonical
			picture=URI.parse("http://www.facebook.com#{page.root.css(".picture_container img").first.attributes["src"].to_s}") rescue nil
			brute_fact facebook_public, :picture, picture			  
			# let the hcard parser take care of the rest
			return
		end
	end

end

