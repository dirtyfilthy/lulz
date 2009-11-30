require 'json'
module Lulz
	class GoogleSocialGraphAgent < Agent

   		default_process :process
	    searcher
	    set_description "search google social graph for profiles with same rel='me' links"   
		
      def self.accepts?(pred)
         object=pred.object
         subject=pred.subject
         if (pred.name==:homepage_url and object.is_a?(URI) and not is_processed?(object))
            return true
         end
         if (object.is_a?(EmailAddress) and not is_processed?(object))
            return true
         end
         if (subject.is_a?(Profile) and subject.respond_to?(:url) and object.is_a?(URI) and object==subject.url and not is_processed?(object))
            return true
         end

         return false
      end



		def process(pred)
         target=pred.object
         web=Agent.get_web_agent
         url="http://socialgraph.apis.google.com/lookup?q=#{target.to_s}&fme=true&edi=true"
         page=web.get(url)
         json=JSON.parse(page.body)
         canonical=json["canonical_mapping"][target.to_s]
         unless json["nodes"].blank?
            
            json["nodes"].each do |k,v|
               next unless v["types"].is_a?(Array) and v["types"].include?("me") or k==canonical
               node=URI.parse(k) rescue nil
               next if node.nil?
               brute_fact target, :social_graph_search_result, node
               
               also_me=[]
               v["nodes_referenced_by"].each do |r,v2|
                  ref=URI.parse(r) rescue nil
                  next if ref.nil?
		  if v2["types"].is_a?(Array) and v2["types"].include?("me")
                     also_me << ref
                  end
               end
               next if also_me.length>30 # ridiculous number
               also_me.each do |ref|
                  brute_fact target, :social_graph_search_result, ref
		end
            end
         end


         set_processed target
		end

      private



	end
end
