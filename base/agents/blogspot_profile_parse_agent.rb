 
module Lulz
   class BlogspotProfileParserAgent < Agent
      default_process :process
      parser
      set_description "parse blogspot profiles"      

      def self.accepts?(pred)
	 
         object=pred.subject
	 return false unless object.is_a?(URI)
	 return false unless object._query_object(:first, :predicate => :is_blogspot_profile_url)
         return false if is_processed?(object)
	 return true
		
      end


      # TODO grab the rest of the data

		def process(pred)
         
         url=pred.subject
         
         set_processed url
			web=Agent.get_web_agent
         page=web.get(url)
         html=page.body
         blogspot_profile=BlogspotProfile.new
         blogspot_profile.url=url
         blogspot_profile.html_page=html
         blogspot_profile.member_id=url.to_s.scan(/^http:\/\/www.blogger.com\/profile\/(\d+)/).first.first rescue nil
         brute_fact blogspot_profile, :blogspot_profile_url, url
         alias_o=Alias.new(html.scan(/<h1>(.*?)<\/h1>/).first.first) rescue nil 
         info={}
         page.root.css("#main li").each do |elem|
            attrib=elem.css("strong").text.strip
            value=elem.text.gsub(attrib,"").strip 
            elem.css("a").each do |a|
               info[attrib]=info[attrib].to_s+"#{a.text}|" unless ["Industry:", "Occupation:"].include?(attrib)
            end
            info[attrib]||=value
         end
	 contact=page.root.css("ul.contact li").first.text.scan(/.*/).first rescue nil

         brute_fact blogspot_profile, :username, alias_o
	 brute_fact blogspot_profile, :email, EmailAddress.new(contact)
         single_fact blogspot_profile, :country, Country.new(info["Location:"]) rescue nil
         single_fact blogspot_profile, :locality, info["Location:"].split("|")[0] rescue nil unless info["Location:"].blank? or info["Location:"].split("|")[0].length<2
         single_fact blogspot_profile, :age, Age.new(info["Age:"])
         single_fact blogspot_profile, :sex, Sex.new(info["Gender:"])
         brute_fact blogspot_profile, :zodiac_sign, info["Astrological Sign:"] 
         brute_fact blogspot_profile, :zodiac_year, info["Zodiac Year:"]
         brute_fact blogspot_profile, :occupation, info["Occupation:"]
         brute_fact blogspot_profile, :industry, Industry.new(info["Industry:"])
         interests=[]
         page.root.css(".favorites a").each {|e| interests << e.text}
         brute_fact blogspot_profile, :interests, interests.join(", ")
         page.root.css("table#blogs tr a").each do |e|
            u=URI.parse(e.attributes["href"].to_s)
            next if u.to_s=~/^http:\/\/www\.blogger\.com\/profile\//
	    brute_fact blogspot_profile,:homepage_url, u
         end
         page.root.css(".followed-blog a").each do |e|
         u=URI.parse(e.attributes["href"].to_s)
           #brute_fact blogspot_profile,:followed_blog, u
         end

              
         return
         end
		end

	end

