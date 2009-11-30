
module Lulz
	class EmailSearchResultAgent < Agent
		default_process :process
      transformer
	 set_description "add emails back to the profiles discovered when searching for them"
      def self.accepts?(pred)
	 
         return true if pred.name==:email_search_result_url and pred.subject.is_a?(EmailAddress) and pred.object.is_a?(URI) and not (is_processed?(pred.object) and is_processed?(pred.subject ))
	      return true if pred.subject.is_a?(Profile) and not is_processed?(pred.subject)
         return false	
      end



		def process(pred)
         if pred.subject.is_a?(EmailAddress)
            url=pred.object
            
            set_processed(url)
	    
            email=pred.subject
	    set_processed(email)
            url._predicates_as_object.each do |p|
               if p.subject.is_a? Profile
                  brute_fact p.subject, :email, email
                  return
               end
            end
         else
            Agent.personal_info_mutex.synchronize {
            set_processed(pred.subject)
            pred.subject._predicates.each do |p1|
               next unless p1.object.is_a?(URI)
               urls=[p1.object]
               p1.object._predicates.each do |p2|
                  urls << p2.object if p2.object.is_a?(URI) and p2.name==:same_owner
               end
               urls.each do |url|
                 url._predicates_as_object.each do |p|
                    if p.name==:email_search_result_url
                        brute_fact pred.subject, :email, p.subject 
                        return
                    end
                  end
               end
            end
            }
         end

      end           
	end

end

