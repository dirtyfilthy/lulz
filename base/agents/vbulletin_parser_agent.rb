
module Lulz
   class VbulletinParserAgent < Agent
      default_process :process
      parser 
      set_description "parse vbulletin profiles"


      def self.accepts?(pred)
	 
         object=pred.subject
	 return false unless object.is_a?(URI)
	 return false unless object._query_object(:first, :predicate => :is_vbulletin_url)
         return false if is_processed?(object)
	 return true
		
      end



      def process(pred)
         
         url=pred.subject
         set_processed url
	 web=Agent.get_web_agent
         page=web.get(url)
         html=page.body
          
         vbulletin_profile=VbulletinProfile.new
         vbulletin_profile.url=url
         vbulletin_profile.html_page=html
         brute_fact vbulletin_profile, :profile_url, url
         brute_fact vbulletin_profile, :username, Alias.new(html.scan(/View Profile: ([a-zA-Z0-9_-]+)/i).first.first) rescue nil
	 
	 attributes=html.scan(/<strong>([a-zA-Z0-9 ]+)<\/strong>:*?<br \/>(.*?)<\/td>/m)
	 attributes=html.scan(/<dt class="shade">(.*?)<\/dt>.*?<dd>(.*?)<\/dd>/m) if attributes.blank?
	 homepage_url=URI.parse(html.scan(/Home Page:.*?<a href="(.*?)"/m).first.first) rescue nil
	 brute_fact vbulletin_profile, :homepage_url, homepage_url
	 attributes.each do |attribute|
	    key,value=attribute
	    value.strip!
	    case key.downcase
	       when "age"
		  brute_fact vbulletin_profile, :age, Age.new(value)
	       when "country"
		  single_fact vbulletin_profile, :country, Country.new(value)
	       when "location"
		  single_fact vbulletin_profile, :country, Country.new(value)
	       when "city"
		  brute_fact vbulletin_profile, :city, Locality.new(value)
	       when "occupation"
		  brute_fact vbulletin_profile, :occupation, value
	       when "date of birth"
		  single_fact vbulletin_profile, :date_of_birth, BirthDate.new(value)
	    
	       when "home page"
				 url=URI.parse(url) rescue nil
		  brute_fact vbulletin_profile, :homepage_url, value
		 end
	 end
	 
	 # let the hcard parser take care of the rest
         return
      end

   end
end

