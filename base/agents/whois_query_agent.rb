require "lib/whois.rb"
module Lulz
	class WhoisQueryAgent < Agent
	    searcher
	    set_description "query whois database for domain info"
		default_process :process
      EXCLUDED=%w(deviantart.com geocities.com ihug.co.nz wordpress.com livejournal.com google.com google.co.nz blogspot.com blogger.com flickr.com twitter.com digg.com myspace.com youtube.com greatestjournal.com)
      def self.accepts?(pred)
         object=pred.object
         return false unless object.is_a?(URI::HTTP)
         domain=Whois::whois_domain(object.host)
         world=pred.world
         domain=world.normalize_object(domain)
         return false if domain.blank?
			if (pred.name==:homepage_url and not EXCLUDED.include?(domain) and not is_processed?(domain))
	    return true
         end
         return false
      end


      # TODO grab the rest of the data

		def process(pred)
	
         url=pred.object
	      domain=Whois::whois_domain(url.host)
	      whois=Whois::perform_search(domain)
         unless whois["registrant_contact_name"].blank?
            p=WhoisRegistrantContactProfile.new
            p.domain=domain
            brute_fact p, :whois_domain, domain
            add_attributes("registrant", whois, p)
         end
         set_processed domain
		end

      private

      def add_attributes(prefix, whois, p)
          nm=Name.new(whois["#{prefix}_contact_name"])
          cn=Country.new(whois["#{prefix}_contact_country"])
          lo=Locality.new(whois["#{prefix}_contact_city"])
          em=EmailAddress.new(whois["#{prefix}_contact_email"])
          pn=PhoneNumber.new(whois["#{prefix}_contact_phone"])
          single_fact p,:name,nm
          single_fact p,:country,cn
          brute_fact p,:email,em
          brute_fact p,:phone_number,pn
          single_fact p,:city,lo
      end


	end
end
