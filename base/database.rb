SQLITE3_DB="#{LULZ_DIR}/db/lulz.sqlite3"
require "activerecord"
module ActiveRecord
	class Base
		# sqlite3 adapter reuses sqlite_connection.
		def self.sqlite3_connection(config) # :nodoc:
			parse_sqlite_config!(config)

			unless self.class.const_defined?(:SQLite3)
				require_library_or_gem(config[:adapter])
			end

			db = SQLite3::Database.new(
				config[:database],
				:results_as_hash => true,
				:type_translation => false
			)

			db.busy_timeout(config[:timeout]) unless config[:timeout].nil?
			
			IdentityBayes::steal_db_handle(db.handle)
			ConnectionAdapters::SQLite3Adapter.new(db, logger, config)
		end
	end
end

	module Lulz

		def self.start_db
			IdentityBayes::set_database(SQLITE3_DB);
			con=ActiveRecord::Base.establish_connection(  
																	  :adapter  => 'sqlite3',   
																	  :database => SQLITE3_DB, 
																	  :pool => 50,   
																	  :timeout => 10000
																	 )
		end

	end


