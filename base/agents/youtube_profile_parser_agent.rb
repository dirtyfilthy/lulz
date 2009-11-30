
module Lulz
	class YoutubeProfileParserAgent < Agent

		default_process :process
	 parser
	 set_description "parse youtube profiles"
      def self.accepts?(pred)
         object=pred.subject
         return (object.is_a?(URI::HTTP) and object._query_object(:first, :predicate => :youtube_profile_url) and not is_processed?(object))
      end


		def process(pred)
         url=pred.subject
			web=Agent.get_web_agent
         page=web.get(url)
         
         html=page.root.to_html
         youtube_profile=YoutubeProfile.new
         youtube_profile.url=url
         brute_fact youtube_profile, :profile_url, url
         alias_o=Alias.new(html.scan(/([A-Za-z0-9_-]+)'s Channel/).first.first) rescue nil
         brute_fact youtube_profile, :username, alias_o 
         age=Age.new(page.root.css("#profile_show_age").first.text) rescue nil
			channel_title=(page.root.css("#channel_title").first.text.strip) rescue nil

			country=Country.new(page.root.css("#profile_show_country").first.text) rescue nil
         same_owner url,youtube_profile
         single_fact youtube_profile, :age, age
			brute_fact youtube_profile, :channel_title, channel_title
         single_fact youtube_profile, :country, country
         brute_fact youtube_profile, :username, alias_o 
         set_processed url
         return
         end
		end

	end

