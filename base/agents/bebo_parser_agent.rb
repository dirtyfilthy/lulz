
module Lulz
	class BeboParserAgent < Agent

	 default_process :process
	 parser
	 set_description "parse bebo profile"

      def self.accepts?(pred)
         object=pred.subject
         return (object.is_a?(URI::HTTP) and object._query_object(:first, :predicate => :is_bebo_url) and not is_processed?(object))
      end


      # TODO grab the rest of the data

		def process(pred)
            url=pred.subject
			   web=Agent.get_web_agent
            page=web.get(url)
            html=page.root.to_html
            bebo_profile=BeboProfile.new
            bebo_profile.url=url
            alias_match=html.scan(/Profile from (.*?) &lt;(.*?)&gt;/)
            name=Name.new(alias_match[0].first) rescue nil
            alias_o=Alias.new(alias_match[0][1]) rescue nil
            country=Country.new(html.scan(/bebo_country_([a-z][a-z])/).first.first) rescue nil
            sex, age = html.scan(/<td>(Male|Female)<\/td>.<td>(\d+)<\/td>/m)[0]
            sex, age = html.scan(/(Male|Female), (\d+),/)[0] if sex.blank?
	    age=Age.new(age)
            sex=Sex.new(sex)
	    country=Country.new(page.root.css(".hometown").first.text) rescue nil if country.blank?
	    	    
            brute_fact bebo_profile, :profile_url, url
            same_owner url,bebo_profile
            single_fact bebo_profile, :sex, sex
            single_fact bebo_profile, :age, age
            single_fact bebo_profile, :country, country
            brute_fact bebo_profile, :username, alias_o 
            single_fact bebo_profile, :name, name
            set_processed url

         return
         end
		end

	end

