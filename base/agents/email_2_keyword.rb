module Lulz
   class Email2KeywordAgent < Agent
	
      default_process :transform
      transformer
      set_description "convert top level email domain to keyword and add back to profile"
      def self.accepts?(pred)
         object=pred.object
         return (object.is_a?(Lulz::EmailAddress) and pred.subject.is_a?(Profile) and not is_processed?(pred)) 
      end
      def transform(pred)
         set_processed pred
	 email=pred.object
         a=email.to_s.split("@")[1]
			return nil if a.nil?
	 tld=a.split(".").last
	 if ["com","org","info","net"].include? tld
		b=a.split(".")[-2] rescue nil
	 else
		 b=a.split(".")[-3] rescue nil 
	 end
	 return nil if b.nil?
	 return if ["gmail","hotmail","mail"].include? b
         pred2=brute_inference pred.subject, :derived_keyword, b      
			set_clique pred,pred2
		end

	end

end
