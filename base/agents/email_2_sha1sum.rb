require 'digest/sha1'
module Lulz
	class Email2Sha1SumAgent < Agent

		default_process :process
      transformer
      set_description "convert email 2 mbox_sha1sum and add back to profile"
      def self.accepts?(pred)
         return false unless (pred.object.is_a?(EmailAddress))
         return false unless (pred.subject.is_a?(Profile) or pred.subject.is_a?(Person))
         return false if is_processed?(pred)
         return true
      end



		def process(pred)
         profile=pred.subject
         email=pred.object
         
	 e="mailto:#{email.address.to_s.strip}"
         sum=Digest::SHA1.hexdigest(e)
         pred2=brute_inference profile, :mbox_sha1sum,sum 
		   set_processed pred
			set_clique(pred,pred2)
      end




	end
end
