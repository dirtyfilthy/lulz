
module Lulz
   class GithubParserAgent < Agent
      default_process :process
      parser 
      set_description "parse github profiles"


      def self.accepts?(pred)
	 
         object=pred.subject
	 return false unless object.is_a?(URI)
	 return false unless object._query_object(:first, :predicate => :is_github_url)
         return false if is_processed?(object)
	 return true
		
      end



      def process(pred)
         
         url=pred.subject
         set_processed url
	 web=Agent.get_web_agent
         page=web.get(url)
         html=page.body
          
         github_profile=GithubProfile.new
         github_profile.url=url
         github_profile.html_page=html
         brute_fact github_profile, :profile_url, url
         brute_fact github_profile, :username, Alias.new(url.to_s.scan(/http:\/\/github.com\/([a-z0-9_-]+)/).first.first) rescue nil
	 email=html.scan(/<div class="email">(.*?)<\/div>/m).first.first rescue nil
	 homepage=URI.parse(page.root.css('#profile_blog').first.attributes['href'].to_s) rescue nil
	 company=page.root.css('#profile_company').first.text rescue nil
	 unless email.blank?
	    email=email.scan(/decodeURIComponent\('(.*?)'\)/).to_s
	    email=CGI.unescape(email)
	    email=email.scan(/>(.*?)</).to_s	    
	 end
	 brute_fact github_profile, :email, EmailAddress.new(email)
         brute_fact github_profile, :homepage_url, homepage
         brute_fact github_profile, :company, company
	 # let the hcard parser take care of the rest
         return
      end

   end
end

