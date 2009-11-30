require 'pp'
require 'uri'
require 'lib/whois.rb'
module Lulz
	class GoogleAgent < Agent
		PAGES=2
      #also_accept_on :homepage
      default_process :google
      searcher
		one_at_a_time
      set_description "search google for objects convertable to google keywords"
      
      def self.accepts?(pred)
         object=pred.object
	 unless object.is_a?(URI) and pred.name==:homepage_url
		 
		 return false unless object.respond_to?(:google_keywords)
	    return false unless object.google_keywords and object.google_keywords.to_s!="" and object.google_keywords.to_s!='""'
	    return false if is_processed?(object)
	    world=pred.world
	    keywords=object.google_keywords
	    keywords=world.normalize_object(keywords)
	 else
	    keywords="\"#{object.to_s.gsub("http://","")}\""
	 end
	 return false if is_processed?(keywords)
	 return true
      end

		def google(pred)
         object=pred.object
			urls=[]
	 keywords="\"#{object.to_s.gsub("http://","")}\"" if object.is_a?(URI)
	 keywords=object.google_keywords unless object.is_a?(URI)

         set_processed object
         set_processed keywords
         web=Agent.get_web_agent
            0.upto(PAGES-1) do |start|

			l="http://www.google.com/search?hl=en&lr=&num=100&q=#{CGI.escape(keywords)}&start=#{start*100}&sa=N"

			   page=web.get(l)
			      urls=urls+page.search("//*[@class='l']").map{|p| p.attributes["href"]}
               sleep(rand(5)+1)
            end
         
         urls.map!{|u| URI.parse(u) rescue nil}
         urls.delete(nil)
         urls.uniq!
         # heuristic to deal with large numbers of  results from a single site
         
			if object.is_a?(Name) or object.is_a?(Alias)
            t=object.to_s.gsub("_","-")
            domain_hash={}
            new_urls=[]
            urls.each do |url|
               domain=Whois::whois_domain(url.host)
               domain_hash[domain]||=[]
               domain_hash[domain]<<url
            end
            domain_hash.each_value do |d_urls|
               d_urls.delete_if{|url| !url.to_s.include?(t)} if d_urls.length > 15
               new_urls+=d_urls
            end
            urls=new_urls
        end
         urls.each do |u| 
            brute_fact object,:google_search,u
         end
		end

	end

end
