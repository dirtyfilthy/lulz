require 'digest/sha1'
module Lulz
	class Name2FirstLastNamesAgent < Agent

		default_process :process
      transformer
      set_description "convert a full name to first and last names"
      def self.accepts?(pred)
         return false unless (pred.object.is_a?(Name))
         return false unless (pred.object.is_full_name?)
			return false unless (pred.subject.is_a?(Profile))
         return false if is_processed?(pred)
         return true
      end



		def process(pred)
         profile=pred.subject
         name=pred.object
         pred2=brute_inference profile, :first_name, name.first_name
			pred3=brute_inference profile, :last_name, name.last_name
		   set_processed pred
			set_clique(pred,pred2)
			set_clique(pred,pred3)
		end




	end
end
