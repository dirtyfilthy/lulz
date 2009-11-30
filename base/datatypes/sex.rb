module Lulz
	class Sex

     equality_on :sex
	
      def initialize(s=nil)
         f=s.to_s.strip.downcase[0,1] rescue ""
         case f
            when 'm'      
               self.sex="Male"
            when 'f'
               self.sex="Female"
            end
      end



	end
end
