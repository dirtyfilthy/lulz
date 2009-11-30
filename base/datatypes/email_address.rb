module Lulz
	class EmailAddress

      equality_on :address
	
      def initialize(address=nil)
         self.address=address
      
      end


		def is_googlable?
			true
		end

		def google_keywords
			address.to_s.gsub("."," ")

		end


	end
end
