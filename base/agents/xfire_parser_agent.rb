
module Lulz
	class XFireProfileParserAgent < Agent

		default_process :process
	    parser
	    set_description "parse xfire profiles"
      def self.accepts?(pred)
         object=pred.subject
         return (object.is_a?(URI::HTTP) and object._query_object(:first, :predicate => :is_xfire_url) and not is_processed?(object))
      end


      # TODO grab the rest of the data

		def process(pred)
         url=pred.subject
			web=Agent.get_web_agent
         page=web.get(url)
         html=page.root.to_html
         
         xfire_profile=XFireProfile.new
         xfire_profile.url=url
         xfire_profile.html_page=html
         brute_fact xfire_profile, :profile_url, url
         labels=[]
         data=[]
         page.root.css(".profile_table>span").each do |element|
            case element.attributes["class"].to_s
            when "profile_label"
               labels << element.text.strip
            when "profile_data"
               data << element.text.strip
            end
         end
         info=Hash.new
         0.upto labels.length do |i|
            info[labels[i]]=data[i]
         end
         brute_fact xfire_profile, :username, Alias.new(info["Username:"])
         brute_fact xfire_profile, :nickname, Alias.new(info["Nickname:"])
         single_fact xfire_profile, :country, Country.new(info["Location:"])
         single_fact xfire_profile, :age, Age.new(info["Age:"])
         single_fact xfire_profile, :sex, Sex.new(info["Gender:"])
         brute_fact xfire_profile, :gamer_style, info["Gaming Style:"]
         single_fact xfire_profile, :name, Name.new(info["Real Name:"])

         set_processed url
         return
         end
		end

	end

