module Lulz
	class PhoneNumber

      equality_on :number
	
      def initialize(number=nil)
         self.number=number.to_s
      
      end


		def is_googlable?
			true
		end

		def google_keywords
			number.to_s

		end


	end
end
