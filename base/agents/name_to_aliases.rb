module Lulz
   class Name2Alias < Agent
	
		default_process :transform
      transformer
      set_description "permutate a name to possible aliases"
      def self.accepts?(pred)
         return false
         object=pred.object
         return (object.is_a?(Lulz::Name) and not is_processed?(object)) 
      end
		def transform(pred)
         name=pred.object
         aliases=[]
         aliases << name.to_s.gsub(" ","").downcase
         aliases << name.to_s.gsub(" ","_").downcase
         
         aliases.uniq!
         aliases=aliases - [name.to_s.downcase]
         aliases.each do |a|
            alias_obj=Alias.new(a)
            add_to_world alias_obj
            brute_fact name, :derived_alias, alias_obj
         end
         set_processed name
		end

	end

end
