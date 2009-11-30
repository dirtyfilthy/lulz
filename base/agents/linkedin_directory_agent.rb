module Lulz
	class LinkedinDirectoryAgent < Agent

		default_process :process
	 searcher
	 set_description "search the linked in directory for a name"
      def self.accepts?(pred)
         return false unless (pred.object.is_a?(Name))
         return false if is_processed?(pred.object)
         first=pred.object.to_s.split.first
         last=pred.object.to_s.split.last
         return (first!=last)

      end



		def process(pred)
         target=pred.object
         first=target.to_s.split.first
         last=target.to_s.split.last
         web=Agent.get_web_agent
         url="http://www.linkedin.com/pub/dir/#{first}/#{last}"
         puts url
			page=web.get(url)
         html=page.root.to_html
         if html =~ /<body id="www-linkedin-com" class="public-profile">/
            # handle only one profile on search
            pp body 
            url=page.uri
            brute_fact target, :linkedin_url, url
            brute_fact url, :is_linkedin_url, true
         else
            directory_entries=html.scan(/<div class="indyloc">(.*?)<br>(.*?)<\/div>.*?<h2><strong><a href="(.*?)"(.*?)<\/tr>/m)
            pp directory_entries
				directory_entries.each do |entry| 
               location, industry, href, misc = entry
               location.gsub!(/[^a-zA-Z ]/,"")
               industry.gsub!(/[^a-zA-Z ]/,"")
               title=misc.scan(/<h3 class="headline">(.*?)<\/h3>/m).first.first.strip rescue nil
               profile=LinkedinDirectoryProfile.new
               profile.linkedin_url=URI.parse(href)
               
               brute_fact profile, :linkedin_url, URI.parse(href)
               brute_fact profile, :name, target
               industry=Industry.new(industry.strip)
               brute_fact profile, :industry, industry
               country=Country.new(location)
               country=Country.new("United States") if country.blank?
               brute_fact profile, :title, title
               single_fact profile, :country, country
            end
         end
         set_processed target
		end

      private



	end
end
