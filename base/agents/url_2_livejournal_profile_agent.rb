require 'pp'
module Lulz
	class Url2LivejournalProfile < Agent
		default_process :get
		parser
	       set_description "parse livejournal profiles"
		def self.accepts?(pred)
         object=pred.subject
			return (object.is_a?(URI) and object._query_object(:first, :predicate => :livejournal_url) and not self.is_processed?(object))
		end

		def get(pred)
         
         url=pred.subject
	
			lj=Lulz::LivejournalProfile.new
			web=Agent.get_web_agent
			page=web.get(url)
			   
         lj.url=url
			lj.html_page=page.root.to_html
         bio=Bio.new(page.root.css("#bio_body").first.to_html) rescue nil
			alias_o=Alias.new(url.to_s.scan(/^http:\/\/users.livejournal.com\/(.*?)\/profile/)[0].first) rescue nil
			brute_fact lj, :username, alias_o
         pred=brute_fact lj, :url, url
         brute_fact lj, :bio, bio
         set_processed url 
		end

	end

end
