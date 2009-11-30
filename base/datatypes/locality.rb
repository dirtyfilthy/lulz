module Lulz
	class Locality

      equality_on :locality
	
      def initialize(local=nil)
         self.locality=local.to_s.downcase.strip
      
      end




	end
end
