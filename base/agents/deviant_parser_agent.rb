
module Lulz
	class DeviantParserAgent < Agent

	 default_process :process
	 parser
	 set_description "parse deviant art profiles"

      def self.accepts?(pred)
         object=pred.subject
         return (object.is_a?(URI::HTTP) and object._query_object(:first, :predicate => :deviant_art_url) and not is_processed?(object))
      end


		def process(pred)
            url=pred.subject
			   web=Agent.get_web_agent
            page=web.get(url)
            html=page.root.to_html
            deviant_profile=DeviantArtProfile.new
            deviant_profile.url=url
            age, sex, country = html.scan(/<dd class="f h">(\d+)\/(\w+)\/([a-zA-Z ]+)<\/dd>/)[0] rescue [nil,nil,nil]
            sex, country = html.scan(/(Male|Female)\/(.*?)<\/span>/).first rescue [nil,nil] if age.nil?
   	      alias_o=Alias.new(url.to_s.scan(/([a-z0-9-]+)\.deviantart\.com/)[0].first) rescue nil
            site=URI.parse(html.scan(/<strong>Website:<\/strong> <a class="h" href="(.*?)">/).first.first) rescue nil
            age=age.to_i rescue nil
            age=Age.new(age)
				country=Country.new(html) if country.nil?
				country=Country.new(country)
            sex=Sex.new(sex)
            same_owner url,deviant_profile
            
            
            brute_fact deviant_profile, :profile_url, url
	         single_fact deviant_profile, :sex, sex
            single_fact deviant_profile, :age, age
            single_fact deviant_profile, :country, country
            brute_fact deviant_profile, :homepage_url, site
            brute_fact deviant_profile, :username, alias_o 
            set_processed url

         return
         end
		end

	end

