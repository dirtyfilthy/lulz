
module Lulz
	class FlickrProfileParserAgent < Agent

		default_process :process
	       parser 
	       set_description "parse flickr profiles"
      def self.accepts?(pred)
         object=pred.subject
         return (object.is_a?(URI::HTTP) and object._query_object(:first, :predicate => :is_flickr_url) and not is_processed?(object))
      end


      # TODO grab the rest of the data

		def process(pred)
            url=pred.subject
			   web=Agent.get_web_agent
            page=web.get(url)
            html=page.root.to_html
            user=html.scan(/photo_navi_contact_span_(\d+@N\d\d)/).first[0]
            canonical_url=URI.parse("http://www.flickr.com/people/#{user}/")
            
            flickr_profile=FlickrProfile.new
            flickr_profile.url=canonical_url
				flickr_profile.html_page=html
				flickr_profile.user_id=user
            alias_o=page.search(".nickname").first.content rescue nil
            alias_o=Alias.new(alias_o)
            sex = html.scan(/I'm <strong>(Male|Female)<\/strong>/).first.first rescue nil
            sex=Sex.new(sex)
         #country=page.search(".country-name").first.content rescue nil
	      #country=Country.new(country)
         #add_to_world country 
	         
            same_owner url,flickr_profile
            
            brute_fact flickr_profile, :profile_url, canonical_url
            single_fact flickr_profile, :sex, sex
            brute_fact flickr_profile, :username, alias_o 
	      #brute_fact flickr_profile, :country, country
            set_processed url
            set_processed canonical_url

         return
         end
		end

	end

