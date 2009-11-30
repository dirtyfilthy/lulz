module Lulz
	class Email2Alias < Agent
	
      	 default_process :transform
	 transformer
	 set_description "convert email to alias"
   	 
      def self.accepts?(pred)
         object=pred.object
         return (object.is_a?(Lulz::EmailAddress) and not is_processed?(object)) 
      end
		def transform(pred)
         email=pred.object
         a=email.to_s.split("@")[0]
         alias_obj=Alias.new(a)
         pred2=brute_inference email, :derived_alias, alias_obj         
         set_processed email
			set_clique(pred,pred2)
		end

	end

end
