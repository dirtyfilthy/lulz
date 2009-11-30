module Lulz
   class Googleable2TwoTermGoogleAgent < Agent
	
      default_process :transform
      transformer
		one_at_a_time
      set_description "convert googleable object to two term search i.e dirtyfilthy new zealand"
      def self.accepts?(pred)
         object=pred.object
         return (object.respond_to?(:google_keywords) and not object.google_keywords.blank? and pred.subject.is_a?(Profile) and not is_processed?(pred)) 
      end

      def transform(pred)
         set_processed pred
	 object=pred.object
	 subject=pred.subject
	 second_terms=[]
	 subject._predicates.each do |pred|  
	    second_terms << pred.object if [Locality,Country].include?(pred.object.class) or pred.name==:keyword or pred.name==:derived_keyword
	    second_terms << pred.object.to_cc if pred.object.is_a?(Country)
	 end
	 second_terms.each do |term|
	    p=brute_inference(object, :second_google_term, term)
	 end

	end

   end
end
