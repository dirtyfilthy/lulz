module Lulz
class PostByHourAgent < Agent
		default_process :process
	    analyzer
		 set_description "analyze posts by hour"
      def self.accepts?(pred)
         subject=pred.subject
         return (pred.subject.is_a? Profile and pred.name == :post and !is_processed?(pred.subject))
      end



		def process(pred)
			subject=pred.subject
			set_processed subject
			words_hash={}
			posts=subject._query_object(:all, :predicate => :post)
			hours={}
			0.upto(23).each do |h|
				hours[h]=0
			end
			posts.each do |post|
				hours[post.posted_at.hour]+=1
			end
			hours.each do |h,num|
				p=PostsByHour.new num
				p.hour=h
				brute_fact_nomatch subject,:posts_by_hour, p
			end
         
			end
		end

	end

