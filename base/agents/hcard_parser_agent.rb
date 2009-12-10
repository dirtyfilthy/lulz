module Lulz
	class HCardParserAgent < Agent

		accept_if_subject_method :html_page
		default_process :parse
      transformer
	 set_description "examine html page for hcard info"
		def parse(pred)
         subject=pred.subject
			
         set_processed subject
         html=subject.html_page
         # TODO: this is cheap and nasty, i need to parse the author of blog properly... later :)
			page=Nokogiri::HTML(html)
			vcard=page.css(".vcard.author").first 
			vcard=page.css(".vcard") if vcard.nil?
			hcard=nil
			unless vcard.nil?

            alias_o=Alias.new(vcard.css(".nickname").first.text) rescue nil
            country=Country.new(vcard.css(".adr .country_name").first.text) rescue nil
            country_l=Country.new(vcard.css(".adr .locality").first.text) rescue nil
            bio=Bio.new(hcard.note) rescue nil 
            country=country_l if country.blank? and not country_l.blank?
            locality=nil
            locality=Locality.new(vcard.css(".adr .locality").first.text) rescue nil if country_l.blank? 
            vcard.css(".url").each do |u| 
					href=URI.parse(u.attributes["href"].to_s) rescue nil
					#pp href	
					brute_fact subject,:homepage_url,href
				end
            picture=URI.parse(vcard.css(".logo").first.attributes["href"].to_s) rescue nil
            firstname=vcard.css(".fn").first.text rescue ""
				lastname=vcard.css(".ln").first.text rescue ""
            name=Name.new("#{firstname} #{lastname}".strip)
            single_fact_once subject, :name,  name
            single_fact_once subject, :country, country
            brute_fact_once subject, :username, alias_o
            single_fact_once subject, :city, locality
            brute_fact_once subject, :picture, picture
            brute_fact_once subject, :bio, bio
            
         end
		end

	end

end
