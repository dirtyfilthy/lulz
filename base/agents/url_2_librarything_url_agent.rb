require 'pp'
require 'uri'
module Lulz
   class Url2LibrarythingUrlAgent < Agent
      default_process :transform
      transformer
      set_description "discover librarything urls"
      def self.accepts?(pred)
         object=pred.object
	 return false unless object.is_a?(URI)
	 return false unless object.to_s=~/^http:\/\/www\.librarything\.com\/profile\/[a-zA-Z0-9_-]+/
	 return false if self.is_processed?(object)
         true
     end

     def transform(pred)
	 object=pred.object
	 user=object.to_s.scan(/http:\/\/www\.librarything\.com\/profile\/([a-zA-Z0-9_-]+)/)
	 user=user.flatten.first.to_s.downcase rescue nil
	 u=URI.parse("http://www.librarything.com/profile/#{user}")
         brute_fact u, :is_librarything_url, true
	 same_owner object,u 
	 set_processed object
      end

   end

end
