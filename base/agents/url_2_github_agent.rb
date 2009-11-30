require 'pp'
require 'uri'
module Lulz
   class Url2GithubUrlAgent < Agent
      default_process :transform
      transformer
      set_description "discover github urls"
      def self.accepts?(pred)
         object=pred.object
	 return false unless object.is_a?(URI)
	 return false unless object.to_s=~/^http:\/\/github\.com\/[A-Za-z0-9._-]+/
	 return false if self.is_processed?(object)
         true
     end

     def transform(pred)
	 object=pred.object
	 user=object.to_s.scan(/http:\/\/github\.com\/([A_Za-z0-9._-]+)/)
	 user=user.flatten.first.to_s.downcase rescue nil
	 u=URI.parse("http://github.com/#{user}")
         brute_fact u, :is_github_url, true
	 same_owner object,u 
	 set_processed object
      end

   end

end
