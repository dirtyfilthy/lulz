require 'pp'
require 'uri'
require 'lib/whois.rb'
module Lulz
	class YahooSearchAgent < Agent
      #also_accept_on :homepage
      default_process :search
      searcher
      set_description "search yahoo for objects with keywords"
      PAGES=2      
      def self.accepts?(pred)
         subject=pred.subject
	 object=pred.object
	 return false unless Resources.get_yahoo_boss_api_key
	 return false unless object.respond_to?(:google_keywords) 
	 keywords="#{object.google_keywords}"
	 return false if is_processed?(keywords)
	 return true
      end

		def search(pred)
	 object=pred.object
	 subject=pred.subject
	 keywords="#{object.google_keywords}"
	 set_processed(keywords)
         web=Agent.get_web_agent
         urls=[]
	 api_key=Resources.get_yahoo_boss_api_key.api_key
	 results=[]
	 0.upto(PAGES) do |start|
	    url="http://boss.yahooapis.com/ysearch/web/v1/#{CGI.escape(keywords)}?appid=#{api_key}&format=xml&count=50&start=#{start*50}"
	    page=web.get(url)
	    results=results+page.body.scan(/<url>(.*?)<\/url>/).map {|u| u.first}	 
	 end
	 results.map!{|u| URI.parse(u) rescue nil}
	 results.delete(nil)
	 results.uniq!
	 results.each {|u| brute_fact object, :yahoo_search, u}
      end

	end

end
