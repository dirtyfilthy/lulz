module Lulz
	class Alias


      equality_on :alias

      def google_keywords
         "#{self.alias}"
      end

      def initialize(a=nil)
         self.alias=a.strip.downcase rescue nil
      
      end
     end

end
