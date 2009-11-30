require 'mofo'
module Lulz
	class HResumeAgent < Agent

		accept_if_subject_method :html_page
		default_process :parse
      transformer
	    set_description "examine html page for hresume info"
#      def self.accepts?(blah)
#         false
#      end

		def parse(pred)
         subject=pred.subject
         set_processed subject
			html=subject.html_page
         hresume=HResume.find :text => html
         # TODO: this is cheap and nasty, i need to parse the author of blog properly... later :)
         hresume=hresume.first if hresume.is_a? Array
         unless hresume.nil?
            hcard=hresume.contact
            alias_o=Alias.new(hcard.nickname) rescue nil
            country=Country.new(hcard.adr.country_name) rescue nil
            country_l=Country.new(hcard.adr.locality) rescue nil 
            country=country_l if country.blank? and not country_l.blank?
            bio=Bio.new(hcard.note) rescue nil
            locality=nil
            locality=Locality.new(hcard.adr.locality) rescue nil  if country_l.blank?
            url=URI.parse(hcard.url) rescue nil
            picture=URI.parse(hcard.logo) rescue nil
            firstname=hcard.fn rescue ""
            lastname=hcard.ln rescue ""
            name=Name.new("#{firstname} #{lastname}".strip)
            brute_fact_once subject, :name,  name
            single_fact_once subject, :country, country
            brute_fact_once subject, :homepage_url, url
            brute_fact_once subject, :username, alias_o
            brute_fact_once subject, :picture, picture
            single_fact_once subject, :city, picture
            brute_fact_once subject, :bio, bio
            doc=Nokogiri(html)
            doc.css('.education.vevent').each do |edu|
               summary=edu.css('.summary').first.text rescue nil
               start=edu.css('.dtstart').first.attributes['title'] rescue nil
               finish=edu.css('.dtend').first.attributes['title'] rescue nil
               finish=edu.css('.dtstamp').first.attributes['title'] if finish.nil? 
               edu_text="#{start.to_s.strip} #{finish.to_s.strip} #{summary.to_s.strip}"
               brute_fact subject, :education, edu_text
            end
            doc.css('.experience.vevent').each do |exp|
               summary=exp.css('.summary').first.text
               title=exp.css('.title').first.text rescue nil
               start=exp.css('.dtstart').first.attributes['title'] rescue nil
               finish=exp.css('.dtend').first.attributes['title'] rescue nil
               finish=exp.css('.dtstamp').first.attributes['title'] rescue nil if finish.nil?
               exp_text="#{start.to_s.strip} #{finish.to_s.strip} #{title.to_s.strip} #{summary.to_s.strip}"
               brute_fact subject, :experience, exp_text
            end
                  
               
            set_processed subject

         end
		end

	end

end
