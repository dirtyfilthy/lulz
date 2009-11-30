module Lulz
   class WhoisRegistrantContactProfile < Profile
	   equality_on :domain
   
      def to_s
	 "WHOIS: #{self.domain}"
      end
   end
end
