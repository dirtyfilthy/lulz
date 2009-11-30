
module Lulz
	class TwitterProfileParserAgent < Agent
	    default_process :process
	    parser
	    set_description "parse twitter profiles"
		 def self.accepts?(pred)
	 
         object=pred.subject
	 return false unless object.is_a?(URI)
	 return false unless object._query_object(:first, :predicate => :is_twitter_url)
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
          
         twitter_profile=TwitterProfile.new
         twitter_profile.url=url
         twitter_profile.html_page=html
         brute_fact twitter_profile, :profile_url, url
         alias_o=Alias.new(html.scan(/\(([a-zA-Z0-9_-]+)\) on Twitter<\/title>/).first.first) rescue nil 
         bio=Bio.new(page.root.css("span.bio").first.to_html) rescue nil
         brute_fact twitter_profile, :username, alias_o
         c=Country.new(page.root.css("span.adr").first.text) rescue nil
         if c.blank?
            c=Country.new(page.root.css("span.adr").first.text.split(",")[1]) rescue nil
         end

         lo=page.root.css("span.adr").first.text.split(",")[0] rescue nil
         tmp_c=Country.new(lo)
         if tmp_c.blank?
            lo=Locality.new(lo)
         else
            lo=nil
         end

         single_fact twitter_profile, :country, c
         single_fact twitter_profile, :city, lo
         single_fact twitter_profile, :bio, bio
           
              
        
         # let the hcard parser take care of the rest
         return
         end
		end

	end

