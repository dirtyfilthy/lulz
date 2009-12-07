
module Lulz
   class PhpbbParserAgent < Agent
      default_process :process
      parser 
      set_description "parse phpbb profiles"


      def self.accepts?(pred)
	 
         object=pred.subject
	 return false unless object.is_a?(URI)
	 return false unless object._query_object(:first, :predicate => :is_phpbb_url)
         return false if is_processed?(object)
	 return true
		
      end



      def process(pred)
         
         url=pred.subject
         set_processed url
	 web=Agent.get_web_agent
         page=web.get(url)
         html=page.body
          
         phpbb_profile=PhpbbProfile.new
         phpbb_profile.url=url
         phpbb_profile.html_page=html
         brute_fact phpbb_profile, :profile_url, url
         #username=html.scan(/Viewing (.*?)'s Profile/i).first.first rescue nil
	 #if username.nil?
			username=html.scan(/Viewing profile :: (.*?)<\/th>/).first.first rescue nil
	    username.gsub!(/<.*?>/,"")
	 #end
	 brute_fact phpbb_profile, :username, username
	 attributes=html.scan(/<tr>.*?<span class=".*?">([a-zA-Z ]+):.*?<\/span>.*?<span class=".*?">(.*?)<\/span>.*?<\/tr>/m)
	 homepage_url=URI.parse(html.scan(/Home Page:.*?<a href="(.*?)"/m).first.first) rescue nil
	 attributes.each do |attribute|
	    key,value=attribute
	    value.strip!
	    value.gsub!("&nbsp;","")
	    key.downcase!
	    case key
	       when "age"
		  single_fact phpbb_profile, :age, Age.new(value)
	       when "location"
		  single_fact phpbb_profile, :country, Country.new(value)
	       when "msn messenger"
		  brute_fact phpbb_profile, :msn, EmailAddress.new(value)
	       when "yahoo messenger"
		  brute_fact phpbb_profile, :yahoo, EmailAddress.new(value)
	       when "e-mail address"
		  brute_fact phpbb_profile, :email, EmailAddress.new(value)
	       when "date of birth"
		  single_fact phpbb_profile, :date_of_birth, BirthDate.new(value)
	       when "occupation"
		  brute_fact phpbb_profile, :occupation, value
			 
	       when "interests"
		  brute_fact phpbb_profile, :interests, value

	       when "website"
		  web=URI.parse(value.scan(/href="(.*?)"/).first.first) rescue nil
		  brute_fact phpbb_profile, :homepage_url, web
	    end
	 end
	 
	 # let the hcard parser take care of the rest
         return
      end

   end
end

