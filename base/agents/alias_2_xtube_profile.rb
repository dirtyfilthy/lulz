
module Lulz
   class Alias2XtubeProfileAgent < Agent
      default_process :process

      set_description "search for alias on xtube"
      searcher
      

      def self.accepts?(pred)
	 
         object=pred.object
	 return false unless object.is_a?(Alias) and object.to_s!=""
         return false if is_processed?(object)
	 return true
		
      end


      # TODO grab the rest of the data

		def process(pred)
         
         a=pred.object
         
         set_processed a

	      web=Agent.get_web_agent
	      url=URI.parse("http://www.xtube.com/community/profile.php?user=#{a}")
         page=web.get(url)
         html=page.root.to_html
	      return nil if html =~ /Sorry, the profile you requested does not exist/
	           
         xtube_profile=XtubeProfile.new
         xtube_profile.url=url
         xtube_profile.html_page=html
	      xtube_profile.username=a.to_s
	    
	      brute_fact xtube_profile, :username, a
         brute_fact xtube_profile, :xtube_profile_url, url
	      sex=Sex.new(page.root.css("#old .gray").first.text) rescue nil 
	    
         single_fact xtube_profile, :sex, sex
            
              
         # let the hcard parser take care of the rest
         return
         end
		end

	end

