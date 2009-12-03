$: << File.dirname( __FILE__) 

require 'rubygems' if Lulz::USE_CLI
require 'web/setup.rb' unless Lulz::USE_CLI
require 'lib/text'
require 'mechanize'
require 'logger'
require 'active_record'
require "base/world.rb"
require "base/constants.rb"
require "base/predicate.rb"
require "base/datatype.rb"
require "base/agent.rb"
require "base/graph.rb"
require "base/action_queue.rb"
require "base/blackboard.rb"
require "base/datatypes/profile.rb"
require "lib/identity_bayes/identity_bayes"
require "base/database.rb"
require "base/models/object_type.rb"
require "base/models/relationship.rb"
require "base/models/markov_predicate"
require "base/models/markov_predicate_chain.rb"
require "base/models/markov_chain_score.rb"
require "base/models/markov_agent_time.rb"
require "base/models/markov_produced_object.rb"
require "base/models/markov_agent_run_profile.rb"
require "base/models/markov_produced_predicate.rb"
require "base/cli.rb" if Lulz::USE_CLI
require "base/resources.rb"
IdentityBayes.set_database(SQLITE3_DB);

module Lulz
	ERROR_LOG=Logger.new "#{LULZ_DIR}/log/error.log"
	DEBUG_LOG=Logger.new "#{LULZ_DIR}/log/debug.log"
	ERROR_LOG.level=Logger::DEBUG
	DEBUG_LOG.level=Logger::DEBUG
	def self.debug(msg)
		DEBUG_LOG.info msg
	end


end
class Object
	include Lulz::Datatype
end

class URI::HTTP
	def to_hash
		return self.to_s.hash
	end
end

class URI::Generic
	def eql?(oth)
		if oth.class==self.class
			return self.component_ary.eql?(oth.component_ary)
		else
			false
		end
	end
end
# require base datatypes
Dir.glob("#{LULZ_DIR}/base/datatypes/*.rb").each {|f| require f }
Dir.glob("#{LULZ_DIR}/base/datatypes/profiles/*.rb").each {|f| require f }
# require base agents
Lulz::start_db
Dir.glob("#{LULZ_DIR}/base/agents/*.rb").each {|f| require f }
b=Lulz::Blackboard.instance
unless Lulz::USE_CLI
	p=Lulz::Person.new
	p.person_id
	b.user_write(p) 
	require "web/start.rb"

else
	Lulz::CLI::parse_options(b)
	Lulz::OPTIONS=b.options
	b.options[:block_until_finished]=true
	b.run unless b.options[:expanded] or b.options[:run_agent]
	matches=b.world.matches
	if b.options[:xml]
		Lulz::CLI::to_xml
		exit
	end
	Lulz::CLI::summary(b) if b.options[:summary]
	b.profiles.clone.sort{|a,b2| a.person_id <=> b2.person_id}.each { |p| 
		next if matches[p].nil? or matches[p]<b.options[:match_threshold]; 
		
		puts p.to_text; 
		puts 
	}
	puts "suggested matches"
	i=0
	#b.world.objects.each do |obj|
	#   puts "#{obj} => #{obj.hash}"
	#end
	sorted=b.profiles.clone.sort { |a1,b1| matches[a1].to_f <=> matches[b1].to_f }.reverse
	sorted.each do |p|
		next if matches[p].to_f<b.options[:match_threshold]
		print "#{p.person_id} (#{sprintf('%.3f',matches[p].to_f)}) "
		i=i+1
	end
	Lulz::CLI::ask_matches(b) if b.options[:match_mode]
	Lulz::World.instance.save if b.options[:match_mode]
end

