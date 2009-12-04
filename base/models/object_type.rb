module Lulz
class ObjectType < ActiveRecord::Base
   @@name_cache={}
   def self.cache_find_or_create_by_name(name)
      return @@name_cache[name] if @@name_cache.key?(name)
      begin
			obj_type=ObjectType.find_or_create_by_name(name)
		rescue ActiveRecord::StatementInvalid
			sleep 0.1
			puts "sleep"
			retry
		end

		@@name_cache[name]=obj_type
      return obj_type
   end
end
end
