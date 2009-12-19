module Lulz
class PostZeitgeistAgent < Agent
		STOP_WORDS=YAML::load_file("#{LULZ_DIR}/config/stopwords.yml")
		default_process :process
	    analyzer
		 set_description "get twenty most common words from posts"
      def self.accepts?(pred)
         subject=pred.subject
         return (pred.subject.is_a? Profile and pred.name == :post and !is_processed?(pred.subject))
      end


      # TODO grab the rest of the data

		def process(pred)
			subject=pred.subject
			set_processed subject
			words_hash={}
			posts=subject._query_object(:all, :predicate => :post)
			posts.each do |post|
				contents=post.contents.clone
				contents.gsub!(/<.*?>/," ")
				
				contents.gsub!(/@[0-9a-zA-Z_-]+/,"") if post.is_a? TwitterPost
				contents.gsub!(/&[a-z]+;/," ")
				words=contents.split(/[^a-zA-Z']/)
				words.map!{|w| w.downcase }
				words=words-STOP_WORDS-[nil]
				words.delete_if{|w| w.blank?}
				words.delete_if{|w| w.length<5}
				words.each do |word|
					words_hash[word] ||= 0
					words_hash[word]+=1
				end
			end
			words=words_hash.keys
			words.sort! {|a,b| words_hash[a]<=>words_hash[b] }
			words.reverse!
			words[0..20].each do |word|
				z=Zeitgeist.new(word)
				z.num_words=words_hash[word]
				brute_fact_nomatch subject, :zeitgeist, z
			end

         
			end
		end

	end

