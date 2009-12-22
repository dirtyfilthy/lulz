module Lulz
class ExtractExternalLinksAgent < Agent
		IGNORE_DOMAINZ=["twimg.com"]
	
		default_process :process
	    analyzer
		 set_description "extract external links"
      def self.accepts?(pred)
			return (!is_processed?(pred) and pred.name!=:external_link)
		end



		def process(pred)
			set_processed(pred)
			subject=pred.subject
			object=pred.object
			top=pred.top_profile
			url=top.url
			url=top.canonical_url if url.nil?
			url=top._query_object(:first, :predicate => :profile_url) if url.nil?
			url=URI.parse(url.to_s) rescue nil
			return if url.nil?
			base=Whois::whois_domain(url.host)
			if subject.respond_to?(:html_page) and !is_processed?(subject)
				scan_for_links(top,base,subject.html_page)
				set_processed(subject)
			end
			if !object.is_a?(URI) and !is_processed?(object) and object.to_s=~/http/
				scan_for_links(top,base,object.to_s)
				set_processed(object)
			end
		end

		def base64_unencode(string)
			begin
				return string.unpack('m').first
			rescue Exception => e
				require 'base64'
				return Base64.decode64(string)
			end

		end

		def scan_for_links(profile,base,html)
			doc=Nokogiri::HTML(html)
			links=html.scan(/<a[\s]+[^>]*?href[\s]?=[\s\"\']+(.*?)[\"\']+.*?>([^<]+|.*?)?<\/a>/).map{|l| l.first}
			links2=html.scan(/[(: -]((?:http|https):\/\/.*?)[ "')]/).map{|l| l.first}
			links=links+links2
			links.uniq!
			links.each do |link|

				# handle msplinks

				if link=~/^http:\/\/www\.msplinks\.com\//
					link=link.gsub(/^http:\/\/www\.msplinks\.com\//,"")
					link=base64_unencode(link)
					link.gsub!(/^\d\d/,"")
				end

				url=URI.parse(link) rescue nil
				next if url.nil?
				next if url.host.blank?
				b2=Whois::whois_domain(url.host)
				next if b2==base or IGNORE_DOMAINZ.include?(b2)
				brute_fact_nomatch profile,:external_link,url, :collect_as => :external_urls
			end
		end

			
		end

	end

