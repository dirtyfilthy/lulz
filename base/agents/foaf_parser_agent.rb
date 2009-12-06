require 'uri'
require "rexml/document"

module Lulz
	class FOAFParserAgent < Agent

		default_process :process
	       parser
	       set_description "parse foaf profiles"
      def self.accepts?(pred)
         object=pred.object
         subject=pred.subject
         return (subject.is_a?(Profile) and object.is_a?(URI) and pred.name==:foaf_url and !is_processed?(pred))
      end


		def process(pred)
         
			url=pred.object
         subject=pred.subject
			set_processed(url)
			web=Agent.get_web_agent
         page=web.get(url)
			xml=page.body
			
			foaf_profile=subject
         doc=Nokogiri::XML xml
			person=doc.xpath("//foaf:Person").first
			person.children.each do |element|
				
				puts "#{element.name}:#{element.text}"
				case element.name
               when "nick"
                  a=Lulz::Alias.new(element.text)
                  brute_fact foaf_profile, :username, a
               when "name"
                  n=Lulz::Name.new(element.text)
                  brute_fact foaf_profile, :name, n
               when "icqChatID"
                  brute_fact foaf_profile, :icq, element.text
               when "mbox_sha1sum"
                  brute_fact foaf_profile, :mbox_sha1sum, element.text
               when "msnChatID"
                  e=EmailAddress.new(element.text)
                  brute_fact foaf_profile, :msn, e
               when "openid"
						u1=element.attributes["rdf:resource"] rescue nil
						u=URI.parse(u1) rescue nil
                  brute_fact u,:openid_url, true
                  brute_fact foaf_profile, :openid,u
               when "homepage"
                  u1=element.attributes["rdf:resource"]
						u=URI.parse(u1) rescue bil
                  brute_fact u,:homepage_url, true
                  brute_fact foaf_profile, :homepage_url,u
               when "weblog"
                  u1=element.attributes["rdf:resource"]
						u=URI.parse(u1) rescue nil
                  brute_fact u,:blog_url, true
                  brute_fact foaf_profile, :homepage_url,u
					when "dateOfBirth"
						b=BirthDate.new(element.text)
						single_fact foaf_profile,:date_of_birth, b
					when "country"
                  u1=element.attributes["dc:title"]
                  c=Country.new(u1)
                  single_fact foaf_profile, :country, c
               when "city"
                  u1=element.attributes["dc:title"]
                  c=Locality.new(u1)
                  single_fact foaf_profile, :city, c


          
           end

         end
         same_owner url,foaf_profile 
         set_processed url
         return
         end
		end

	end

