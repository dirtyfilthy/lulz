
module Lulz
	class TrademeParseAgent < Agent

		default_process :process
	    parser
	    set_description "parse trademe.co.nz profiles"
      def self.accepts?(pred)
         object=pred.subject
         return (object.is_a?(URI) and object._query_object(:first, :predicate => :is_trademe_url) and not is_processed?(object))
      end


      # TODO grab the rest of the data

      def process(pred)
         url=pred.subject
	 web=Agent.get_web_agent
         page=web.get(url)
         member_id=url.to_s.scan(/http:\/\/www\.trademe\.co\.nz.*?member=(\d+)/)
	 html=page.body
         
         trademe_profile=TrademeProfile.new
         trademe_profile.member_id=member_id.first.first
         brute_fact trademe_profile, :profile_url, url
	 alias_match=page.root.css("h3 a b").text
         alias_o=Alias.new(alias_match) rescue nil
	 brute_fact trademe_profile, :username, alias_o
	 name=html.scan(/<b>Name:<\/b><\/small><\/td><td>(.*?)<\/td>/).first.first rescue nil
	 since=html.scan(/<b>Member Since:<\/b><\/small><\/td><td>(.*?)<\/td>/).first.first rescue nil 
	 suburb=html.scan(/<b>Suburb:<\/b><\/small><\/td><td>(.*?)<\/td>/).first.first rescue nil
	 single_fact trademe_profile, :name, Name.new(name)
	 brute_fact trademe_profile, :locality, Locality.new(suburb)
	 brute_fact trademe_profile, :member_since, since
	 single_fact trademe_profile, :country, Country.new("nz")
         
         return
      end
   end

end

