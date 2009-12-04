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
         hcard=HCard.find :text => html
         # TODO: this is cheap and nasty, i need to parse the author of blog properly... later :)
         
	      hcard=hcard[1] if hcard.is_a? Array and subject.is_a? IdenticaProfile # identica is weird
	      hcard=hcard.first if hcard.is_a? Array
         unless hcard.nil?
            alias_o=Alias.new(hcard.nickname) rescue nil
            country=Country.new(hcard.adr.country_name) rescue nil
            country_l=Country.new(hcard.adr.locality) rescue nil
            bio=Bio.new(hcard.note) rescue nil 
            country=country_l if country.blank? and not country_l.blank?
            locality=nil
            locality=Locality.new(hcard.adr.locality) rescue nil if country_l.blank? 
            url=URI.parse(hcard.url) rescue nil
            picture=URI.parse(hcard.logo) rescue nil
            firstname=hcard.fn rescue ""
            lastname=hcard.ln rescue ""
            name=Name.new("#{firstname} #{lastname}".strip)
            brute_fact_once subject, :name,  name
            single_fact_once subject, :country, country
            brute_fact_once subject, :homepage_url, url
            brute_fact_once subject, :username, alias_o
            single_fact_once subject, :city, locality
            brute_fact_once subject, :picture, picture
            brute_fact_once subject, :bio, bio
            
         end
		end

	end

end
