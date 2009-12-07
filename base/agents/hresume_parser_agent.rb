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
         page=Nokogiri::HTML(html)
			hresume=page.css(".hresume").first
         unless hresume.nil?
            hresume.css('.education.vevent').each do |edu|
               summary=edu.css('.summary').first.text rescue nil
               start=edu.css('.dtstart').first.attributes['title'] rescue nil
               finish=edu.css('.dtend').first.attributes['title'] rescue nil
               finish=edu.css('.dtstamp').first.attributes['title'] if finish.nil? 
               edu_text="#{start.to_s.strip} #{finish.to_s.strip} #{summary.to_s.strip}"
               brute_fact subject, :education, edu_text
            end
            hresume.css('.experience.vevent').each do |exp|
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
