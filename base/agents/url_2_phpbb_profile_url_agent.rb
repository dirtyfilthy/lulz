require 'pp'
require 'uri'
module Lulz
   class Url2PhpbbProfileUrlAgent < Agent
      default_process :transform
      transformer
      set_description "discover phpbb profiles"
      def self.accepts?(pred)
         object=pred.object
	 return false unless object.is_a?(URI)
	 return false unless object.to_s=~/\/modules.php\?.*?mode=viewprofile.*?u=\d+$/
	 return false if self.is_processed?(object)
         true
     end

     def transform(pred)
         brute_fact pred.object, :is_phpbb_url, true
	 set_processed pred.object
      end

   end

end
