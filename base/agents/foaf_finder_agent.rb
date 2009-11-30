require 'pp'
require 'uri'
module Lulz
	class FOAFFinderAgent < Agent

		accept_if_subject_method :html_page
		default_process :search
      transformer
      set_description "search html pages for foaf profile links"
		def search(pred)
         object=pred.subject
			html=object.html_page
			page=Nokogiri::HTML(html)
			foaf_links=page.xpath("//link[@title='FOAF']")
			urls=foaf_links.map do |link| link.attributes["href"] end
			urls.map!{|u| URI.parse(u)}
			urls.each do |u|
            brute_fact u, :is_foaf_url, true
            brute_fact object, :foaf_url, u
            same_owner object,u
         end
         set_processed object
		end

	end

end
