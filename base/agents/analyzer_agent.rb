require 'pp'
module Lulz
	class AnalyzerAgent < Agent
		set_description "analyzer agent"		
		def self.accepts?(object)
			false # must be called explicitely
		end

		def analyze(profile)
			produced_predicates=profile._predicates.clone
			agent_types=Agent.analyzer_agents
			while !produced_predicates.empty?
				pred=produced_predicates.pop
				agent_types.each do |at|
					if at.accepts?(pred)
						agent=at.new(World.instance)
						begin
							Blackboard.instance.status_agent(at)
							agent.run(pred)
						rescue Exception => e
							puts e
						end

						produced_predicates=produced_predicates+agent.produced_predicates
					end
				end
			end

		end

	end
end
