module Lulz
   class PgpProfile < Profile
      
      def to_s
	 "PGP KEY: #{key_id}"
      end


	   
      equality_on :key_id
   end

  end
