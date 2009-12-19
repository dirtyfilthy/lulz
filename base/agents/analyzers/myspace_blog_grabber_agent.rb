
module Lulz
	class GrabMyspaceBlogPosts < Agent

		default_process :process
		 set_description "grab myspace blog posts"
			analyzer
		 def self.accepts?(pred)
         subject=pred.subject
         return (pred.subject.is_a? MyspaceProfile and !is_processed?(subject))
      end

		

		def process(pred)
			subject=pred.subject
			set_processed subject
			blog_url=subject.html_page.scan(/http:\/\/blogs.myspace.com\/index\.cfm\?fuseaction=blog\.ListAll&friendId=\d+/).first
			web=Agent.get_web_agent
			page=web.get(blog_url)
			parse_blog_posts(subject,page)
			older=page.root.css("#ctl00_ctl00_cpMain_BlogList_btnOlder").first.attributes["href"].to_s rescue nil
			unless older.blank?
				page=web.get(older)
				parse_blog_posts(subject,page)
				older=page.root.css("#ctl00_ctl00_cpMain_BlogList_btnOlder").first.attributes["href"].to_s rescue nil
			end

		end

		private

		def parse_blog_posts(profile,page)
			rows=page.root.css("#BlogTable tr")
			rows.each do |row|
				timestamp=row.css(".blogTimeStamp").text.strip rescue nil
				next if timestamp.blank?
				subject=row.css(".blogSubject").text.strip rescue nil
				content=row.css(".blogContent").inner_html.strip
				time_cell=row.css(".blogContentInfo .cmtcell").first
				time=time_cell.text
				timestamp="#{timestamp} #{time}"
				canon=time_cell.css("a").first.attributes["href"].to_s
				post=Post.new
				post.subject=subject
				post.posted_at=DateTime.parse(timestamp) rescue nil
				post.canonical_url=URI.parse(canon) rescue nil
				post.contents=content
				brute_fact_nomatch profile,:post,post
			end
		end


	end
end
