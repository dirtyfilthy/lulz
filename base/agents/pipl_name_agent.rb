require 'cgi'
module Lulz
	class  PiplNameAgent < Agent

      searcher
      set_description "search pipl.com for a name"


      def self.accepts?(pred)
         return false unless pred.object.is_a?(Name)
         name=pred.object
         return false unless name.to_s.split.length>1
         return false unless pred.subject.is_a?(Profile) or pred.subject.is_a?(Person)
         country=pred.subject._query_object(:first, :predicate => :country)
         return false if country.blank?
         a="#{name} #{country}"
         a=pred._world.normalize_object(a)
         return false if is_processed?(a)
         return true
         
      end

		default_process :parse
		def parse(pred)
         name=pred.object
         country=pred.subject._query_object(:first, :predicate => :country)
         a=name
         set_processed "#{name} #{country}"
         firstname=name.to_s.split.first
         lastname=name.to_s.split.last 
	      agent=Agent.get_web_agent
         page=agent.get("http://www.pipl.com/")
         form=page.forms[0]
         form["FirstName"]=firstname
         form["LastName"]=lastname
         form["Country"]=country.to_cc

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
