module Lulz
	class Name

     equality_on :name
	
      def initialize(n=nil)
         @name=n.to_s.downcase.strip
	 @name.gsub!(".","")
	 @name.gsub!(/[^a-z0-9 ].*?[^a-z0-9 ]/,"")
      
      end

      def is_full_name?
	 return (self.name.split.length>=2)
      end

		def first_name
			return (self.name.split.first)
		end

		def last_name
			return (self.name.split.last)
		end

      def is_googlable?
	 true
      end

      def google_keywords
	 return false unless self.is_full_name?
	 "\"#{self.name}\""
      end


	end
end
