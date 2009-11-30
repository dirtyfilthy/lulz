require 'cgi'
module Lulz
	class  PiplEmailAgent < Agent
	    searcher
	    set_description "search pipl.com for an email"

      def self.accepts?(pred)
         return (pred.object.is_a?(EmailAddress) and not is_processed?(pred.object))
      end

		default_process :parse
		def parse(pred)
         email=pred.object
         agent=Agent.get_web_agent
         page=agent.get("http://www.pipl.com/email")
         form=page.forms[0]
         form["Email"]=email.to_s
         page=form.submit
         results_url=page.root.to_html.scan(/var resultsURL = '(.*?)';/).first.first rescue nil
         return if results_url.nil?
         sleep 5
	 results_url="http://www.pipl.com#{results_url}"
         page=agent.get(results_url)
         page.root.css(".bLink a").each do |link|
            href=link.attributes["href"]
            url=href.to_s.scan(/U=(.*)/).first.first rescue nil
            next if url.nil?
            
            url=CGI::unescape(url)
            url.gsub!(/><b$/,"")
         
            brute_fact email, :pipl_search_result, URI.parse(url)
            brute_fact email, :email_search_result_url, URI.parse(url)
         end
         set_processed email 
      end

   end

end
