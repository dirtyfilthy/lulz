require 'mkmf'

unless have_header('gmp.h') 
	  $stderr.puts "can't find gmp.h, try --with-gmp-include=<path>"
	    ok = false
end

unless have_header('sqlite3.h') 
	  $stderr.puts "can't find sqlite3"
	    ok = false
end

have_library "gmp"
have_library "sqlite3"

create_makefile("identity_bayes")
