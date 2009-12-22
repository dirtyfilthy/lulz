
module Lulz
	class GrabTrademeInfoAgent < Agent

		default_process :process
		 set_description "grab trademe info"
			analyzer
		 def self.accepts?(pred)
         subject=pred.subject
         return (pred.subject.is_a? TrademeProfile and pred.object.is_a? Alias and pred.name==:username and !is_processed?(pred))
      end

		

		def process(pred)
			subject=pred.subject
			set_processed pred
			web=Agent.get_web_agent
			feedback_fragments=[]
			feedback_url="http://www.trademe.co.nz/Members/Feedback.aspx?member=#{subject.member_id}"
			html=web.get(feedback_url).body
			feedback_fragments+=get_feedback_fragments(html)
			pages=html.scan(/Feedback\.aspx\?member=\d+\&amp;page=(\d+)/)
			pages=pages.map {|p| p[0].to_i}
			max_page=pages.max
			page=2	
			while page<=max_page
				html=web.get("#{feedback_url}&page=#{page}").body
				feedback_fragments+=get_feedback_fragments(html)
				page+=1
			end
			feedback_fragments.each do |fragment|
				auc=parse_auction(fragment)
				brute_fact_nomatch subject, :auction, auc
			end
		
		end

		private

	   def parse_auction(fragment)
			web=Agent.get_web_agent
			auction_id=fragment.scan(/Browse\/Listing.aspx\?id=(\d+)/).first.first.to_s rescue nil
			feedback_from=fragment.scan(/<a href="\/Members\/Listings\.aspx\?member=\d+"><b>(.*?)<\/b>/).first.first.to_s rescue nil
			seller_buyer=fragment.scan(/was the (seller|buyer)<\/span>/).first.first.to_s rescue nil
			feedback_c=fragment.scan(/<td colspan="2"><font color="#006633">(.*?)<\/font>/).first.first rescue nil
			feedback_type=fragment.scan(/src="\/images\/(happy|sad|neutral)_face1.gif"/).first.first.to_s rescue nil
			auction_url="http://www.trademe.co.nz/Browse/Listing.aspx?id=#{auction_id}"
			
			page=web.get(auction_url)
			auction_title=page.root.css("#ListingTitle_title").text.strip
			auction_closed=page.root.css("#ListingTitle_titleTime").text.strip
			auction_closed.gsub!("Closed: ","")
			auction_closed=DateTime.parse(auction_closed) rescue nil
			auction_description=page.root.css("#ListingDescription_ListingDescription").text
			auction_description.gsub!("Please read the questions and answers for this auction.","")
			auction=TrademeAuction.new
			auction.id=auction_id
			auction.closed_at=auction_closed
			auction.as=seller_buyer
			brute_fact_nomatch auction, :title, auction_title.strip
		   brute_fact_nomatch auction, :description, auction_description.strip
			feedback=TrademeFeedback.new
				
			brute_fact_nomatch auction, :feedback, feedback
			
			feedback.feedback_type=feedback_type
			feedback.feedback_from=feedback_from
			feedback.contents=feedback_c.gsub(/&nbsp;$/,"")
			page.root.css(".QuestionBlock").each do |q|
				quest=q.css(".Question").xpath("text()").text.strip 
				next if quest.blank?
				qa=TrademeQA.new
					
				brute_fact_nomatch auction, :question, qa
				brute_fact_nomatch qa, :question, quest rescue nil
				brute_fact_nomatch qa, :answer, q.css(".Answer").xpath("text()").text.strip rescue nil
				qa.asked_by=q.css(".Question small a").first.text rescue nil
			
			end
			return auction
		end	

		def get_feedback_fragments(body)
			body.scan(/<tr valign="top"><td width="18"><IMG(.*?)<hr size="1"/).flatten
		end
		end

	end

