
module Lulz
	class GrabTwitterPostsAgent < Agent

		default_process :process
	    analyzer
		 set_description "grab twitter posts"
      def self.accepts?(pred)
         subject=pred.subject
         return (pred.subject.is_a? TwitterProfile and pred.object.is_a? Alias and pred.name==:username and !is_processed?(pred))
      end


      # TODO grab the rest of the data

		def process(pred)
         subject=pred.subject
			set_processed pred
			web=Agent.get_web_agent
			username=subject._query_object(:first, :predicate => :username).to_s
			base_url="http://twitter.com/statuses/user_timeline.xml?screen_name=#{username}&count=200"
			page=0
			statuses=3200
			while page<16 and (page*200)<statuses do
				u="#{base_url}&page=#{page}"
				xml=web.get(u)
				
				doc=Nokogiri::XML xml.body
				if page==0
					statuses=doc.xpath("/statuses/status[1]/user/statuses_count").text.to_i
					brute_fact_nomatch subject,:status_updates,statuses
				end
				posts=doc.xpath("/statuses/status")
				posts.each do |post|
					canon="http://twitter.com/#{username}/status/#{post.xpath("id").text}"
					twitter_post=TwitterPost.new(canon)
					twitter_post.posted_at=DateTime.parse(post.xpath("created_at").text)
					twitter_post.source=post.xpath("source").text
					twitter_post.in_reply_to=post.xpath("in_reply_to_screen_name").text
					twitter_post.contents=post.xpath("text").text
					brute_fact_nomatch subject, :post, twitter_post
				end
				page=page+1
		
			end

         
			end
		end

	end

