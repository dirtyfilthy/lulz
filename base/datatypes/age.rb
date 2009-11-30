module Lulz
	class Age

     equality_on :age
	
      def initialize(n=nil)
         self.age=n.to_i rescue nil
	 self.age=nil if self.age==0	      
      end



	end
end
