require 'pp'
require 'uri'
require 'lib/whois.rb'
module Lulz
	class TwoTermLocationGoogleAgent < Agent
		PAGES=2
      #also_accept_on :homepage
      default_process :google
      searcher
      set_description "search google for objects with second term (location)  i.e. dirtyfilthy new zealand"
		one_at_a_time      
      def self.accepts?(pred)
         subject=pred.subject
	 object=pred.object
	 return false unless pred.name==:second_google_term
	 return false unless pred.object.is_a?(Country) or pred.object.is_a?(Locality) or pred.object.to_s.length==2
	 return false unless subject.respond_to?(:google_keywords) 
	 return false unless subject.google_keywords and subject.google_keywords.to_s!="" and subject.google_keywords.to_s!='""'
	 keywords="#{subject.google_keywords} #{object.to_s.downcase}"
	 return false if is_processed?(keywords)
	 return true
      end

		def google(pred)
	 object=pred.object
	 subject=pred.subject
	 keywords="#{subject.google_keywords} #{object.to_s.downcase}"
	 set_processed(keywords)
         web=Agent.get_web_agent
         urls=[]
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
