require 'cgi'
module Lulz
	class  PiplAliasAgent < Agent
	 searcher
	 set_description "search pipl.com for an alias"
      def self.accepts?(pred)
         return (pred.object.is_a?(Alias) and not is_processed?(pred.object))
      end

		default_process :parse
		def parse(pred)
         a=pred.object
         set_processed a 
	agent=Agent.get_web_agent
         page=agent.get("http://www.pipl.com/username")
         form=page.forms[0]
         form["Username"]=a.to_s
         page=form.submit
         results_url=page.root.to_html.scan(/var resultsURL = '(.*?)';/).first.first rescue nil
         return if results_url.nil?
         results_url="http://www.pipl.com#{results_url}&t=#{(Time.now.to_f*1000).to_i}"
         sleep 1
	 page=agent.get(results_url)
         page.body.scan(/U=(.*?)"/).uniq.each do |link|
            url=link[0]
            next if url.nil?
            
            url=CGI::unescape(url)
            url.gsub!(/><b$/,"")
            brute_fact a, :pipl_search_result, URI.parse(url)
         end
	 toggle=page.body.scan(/toggle\('(.*?)'\)/).first.first rescue nil
	 unless toggle.nil?
		n,s=results_url.scan(/N=(.*?)&P=root&S=(.*?)&/).first
		additional_results="http://www.pipl.com/cache/\?N=#{n}&S=#{s}&P=#{toggle}.htm"
      page=agent.get(additional_results)
		page.body.scan(/U=(.*?)"/).uniq.each do |link|
            		url=link[0]
           		 next if url.nil?
            		url=CGI::unescape(url)
            		url.gsub!(/><b$/,"")
                   
            		brute_fact a, :pipl_search_result, URI.parse(url)
         	end
  	  end
          
      end

   end

end
