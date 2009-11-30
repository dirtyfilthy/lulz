
module Lulz
	class MySpaceParseAgent < Agent

		default_process :process
	    parser
	    set_description "parse myspace profiles"
      def self.accepts?(pred)
         object=pred.subject
         return (object.is_a?(URI) and object._query_object(:first, :predicate => :is_myspace_url) and not is_processed?(object))
      end


      # TODO grab the rest of the data

		def process(pred)
         url=pred.subject
			web=Agent.get_web_agent
         page=web.get(url)
         html=page.body
         
         alias_match=html.scan(/<link rel="canonical" href="http:\/\/www.myspace.com\/([a-z0-9_-]+)/).first.first rescue nil
         
			#name,alias2=html.scan(/([a-zA-Z0-9_-]+) \(([a-zA-Z0-9`'_- ]+)\) \| MySpace/).first rescue [nil, nil]    
			
			alias2,name=html.scan(/([a-zA-Z0-9_-]+) \(([a-zA-Z0-9 ]+)\) \| MySpace/).first rescue [nil, nil]    
			canonical_url=URI.parse("http://www.myspace.com/#{alias_match}")
         set_processed canonical_url
         set_processed url         
         myspace_profile=MyspaceProfile.new
         myspace_profile.url=canonical_url
         brute_fact myspace_profile, :profile_url, canonical_url
         alias_o=Alias.new(alias_match) rescue nil
	      sex, age, region, country = html.scan(/(Male|Female).*?<br.*?>(\d+) years old.*?<br.*?>(.*?)<br.*?>(.*?)<br.*?>/mi)[0]
         if country.blank?
            country=html.scan(/<br><br>.*Last Login/m).first
         end
	 if sex.nil?
	    sex=html.scan(/(Male|Female)/).first.to_s rescue nil
	 end
         if country.blank?
	    country=html.scan(/<span class="country-name">(.*?)<\/span>/).first.to_s rescue nil
	 end
	 if age.blank?
	    age=html.scan(/<span class="age">(.*?)<\/span>/).first.to_s rescue nil?
	 end
	 if age.blank?
	    age=html.scan(/(\d+) years old/i).first.to_s rescue nil
	 end
	 region=html.scan(/<span class="region">(.*?)<\/span>/).first.to_s if region.blank? 	 
         age=Age.new(age)
         sex=Sex.new(sex)
	      country=Country.new(country)
	      locality=Locality.new(region)
	      same_owner url,myspace_profile
         single_fact myspace_profile, :sex, sex
			brute_fact myspace_profile, :name, Name.new(name)
			single_fact myspace_profile, :alias, Alias.new(alias2) if alias_match!=alias2
         single_fact myspace_profile, :age, age
         brute_fact myspace_profile, :username, alias_o 
	 brute_fact myspace_profile, :region, locality
	      single_fact myspace_profile, :country, country
         
         return
         end
		end

	end

