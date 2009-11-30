module Lulz
class Relationship < ActiveRecord::Base
   @@relationship_cache={} 
   def self.cache_find_or_create_by_name(name)
      return @@relationship_cache[name] if @@relationship_cache.key?(name)
      rel=Relationship.find_or_create_by_name(name)
      @@relationship_cache[name]=rel
      return rel
   end

end
end
