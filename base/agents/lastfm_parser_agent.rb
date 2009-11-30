
module Lulz
	class LastfmProfileParserAgent < Agent
		default_process :process
	    parser
	    set_description "parse lastfm profiles"
      def self.accepts?(pred)
	 
         object=pred.subject
	      return false unless object.is_a?(URI)
	      return false unless object._query_object(:first, :predicate => :is_lastfm_url)
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
          
         lastfm_profile=LastfmProfile.new
         lastfm_profile.url=url
         lastfm_profile.html_page=html
         brute_fact lastfm_profile, :profile_url, url
         brute_fact lastfm_profile, :username, Alias.new(url.to_s.scan(/user\/([a-z0-9_-]+)/).first.first) rescue nil
         ui=page.root.css(".userInfo").text
         single_fact lastfm_profile, :sex, Sex.new(ui.scan(/Male|Female/).first) rescue nil  
         single_fact lastfm_profile, :age, Age.new(ui.scan(/\d\d.*?Last seen/).first) rescue nil
         photo=page.root.css("img.photo").first.attributes['src'].to_s rescue nil
         brute_fact lastfm_profile, :picture, URI.parse(photo) unless photo.blank? or photo=~/default/
         
         # let the hcard parser take care of the rest
         return
         end
		end

	end

