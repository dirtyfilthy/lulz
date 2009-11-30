
module Lulz
   class LibrarythingParserAgent < Agent
      default_process :process
      parser 
      set_description "parse librarything profiles"


      def self.accepts?(pred)
	 
         object=pred.subject
	 return false unless object.is_a?(URI)
	 return false unless object._query_object(:first, :predicate => :is_librarything_url)
         return false if is_processed?(object)
	 return true
		
      end



      def process(pred)
         
         url=pred.subject
         set_processed url
	 web=Agent.get_web_agent
         page=web.get(url)
         html=page.body
          
         librarything_profile=LibrarythingProfile.new
         librarything_profile.url=url
         librarything_profile.html_page=html
         brute_fact librarything_profile, :profile_url, url
         brute_fact librarything_profile, :username, Alias.new(url.to_s.scan(/http:\/\/www.librarything.com\/profile\/([a-z0-9_-]+)/).first.first) rescue nil
			attributes=html.scan(/<span class="left">([a-zA-Z ]+)<\/span>(.*?)(?:<\/p>|<p>)/)
			attributes.each do |key,value|
				case key.downcase
					when "homepage"
						url=URI.parse(value.scan(/a href="(.*?)"/).first.first) rescue nil
						brute_fact librarything_profile, :homepage_url,url
					when "location"
						single_fact librarything_profile, :country, Country.new(value)
					when "about me"
						brute_fact librarything_profile, :bio, value
					when "also on"
						urlz=value.scan(/href=['"](.*?)['"]/)
						urlz.map!{|u| URI.parse(u.first) rescue nil}
						urlz.each do |url|
							brute_fact librarything_profile, :homepage_url, url
						end
					when "email"
						email=value.gsub(/<.*?>/,"@")
						brute_fact librarything_profile, :email, EmailAddress.new(email)
				end
			end
			return
      end

   end
end

