SQLITE3_DB="#{LULZ_DIR}/db/lulz.sqlite3"
require "active_record"
module Lulz
   
   def self.start_db
      ActiveRecord::Base.establish_connection(  
         :adapter  => 'sqlite3',   
         :database => SQLITE3_DB, 
         :pool => 50,   
         :timeout => 10000
	)
   end

end


