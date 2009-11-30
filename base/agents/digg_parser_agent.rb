
module Lulz
   class DiggProfileParserAgent < Agent

      default_process :process
      parser
      set_description "parse digg profiles"

      def self.accepts?(pred)
         object=pred.subject
         return (object.is_a?(URI::HTTP) and object._query_object(:first, :predicate => :is_digg_url) and not is_processed?(object))
      end


      # TODO grab the rest of the data

		def process(pred)
         url=pred.subject
	 
         set_processed url
	 web=Agent.get_web_agent
         page=web.get(url)
         html=page.root.to_html
         
         digg_profile=DiggProfile.new
         digg_profile.url=url
         digg_profile.html_page=html
         brute_fact digg_profile, :profile_url, url
	# let the hcard parser take care of the rest
         return
         end
		end

	end

