require 'pp'
require 'uri'
module Lulz
   class Url2TrademeUrl < Agent
      default_process :transform
      transformer
      set_description "discover trademe urls"
      def self.accepts?(pred)
	 object=pred.object
	 return false unless object.is_a?(URI)
	 return false unless object.to_s=~/^http:\/\/www\.trademe\.co\.nz.*?member=\d+/
	 return false if self.is_processed?(object)
         true
      end

      def transform(pred)
	 object=pred.object
	 member=object.to_s.scan(/http:\/\/www\.trademe\.co\.nz.*?member=(\d+)/)
         member=member.flatten.first.to_s rescue nil
	 u=URI.parse("http://www.trademe.co.nz/Members/Profile.aspx?member=#{member}")
	 brute_fact u, :is_trademe_url, true
	 same_owner object,u 
	 set_processed object
	 set_processed u
      end

   end

end
