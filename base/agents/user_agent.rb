require 'pp'
module Lulz
	class UserAgent < Agent
	    set_description "agent representing user added info"		
		 def self.accepts?(object)
		 	false
		 end

       def add_object(obj)
          add_to_world obj
          brute_fact obj, :user_add, obj # mooo is placeholder, fix
      end
	end

end
