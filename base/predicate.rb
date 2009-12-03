module Lulz
	class Predicate
		attr_accessor :creator
		attr_accessor :name
		attr_accessor :subject
		attr_accessor :object
		attr_accessor :probability
		attr_accessor :world
		attr_accessor :type
		attr_accessor :last_profile_object
		attr_accessor :last_search_agent
		attr_reader :created_at
		attr_accessor :person_pred      
		attr_accessor :created_from 
		attr_writer :was_relevant 
		attr_reader :id
		attr_accessor :ran_by
		attr_accessor :tested_agents 
		attr_accessor :clique
		@@idz=0
		@@id_mutex=Monitor.new
		@@cliq_mutex=Monitor.new
		@@cliquez=1
		@@all_predicates={}
		@@clique_hash={}

		alias :relationship :name

		def runnable_by?(agent)
			self.tested_agents << agent.to_s unless self.tested_agents.include?(agent.to_s) or agent.too_many_agents?
			return agent.accepts?(self)
		end
		def self.new_clique
			cliq=@@cliquez
			@@cliquez=@@cliquez+1
			return cliq
		end

		def self.set_clique(pred1,pred2)
			return if pred1.nil? or pred2.nil?
			@@cliq_mutex.synchronize {
				clique1=pred1.clique
				clique2=pred2.clique
				return if clique1!=0 and clique1==clique2

				new_cliq=Predicate.new_clique
				if(clique1==0 and clique2==0)
					pred1.clique=new_cliq
					pred2.clique=new_cliq
					@@clique_hash[new_cliq]=[pred1,pred2]
					return
				end
				@@clique_hash[clique1]||=[pred1]
				@@clique_hash[clique2]||=[pred2]
				combined=@@clique_hash[clique1]+@@clique_hash[clique2]
				combined.each {|p| p.clique=new_cliq }
				@@clique_hash.delete(clique1)
				@@clique_hash.delete(clique2)
				@@clique_hash[new_cliq]=combined
				return
			}
		end


		def self.new_id
			@@id_mutex.synchronize {
				id=@@idz
				@@idz=@@idz+1
				return id
			}
		end	

		def self.find_by_id(id)
			return @@all_predicates[id]
		end


		def initialize
			@created_at=Time.now
			@created_from=[]
			@was_relevant=false
			@id=Predicate.new_id
			@@all_predicates[@id]=self
			@cutout=nil
			@chain=nil
			@ran_by=[]
			@clique=0
			@tested_agents=[]
		end

		def expand
			produced_predicates=[]
			agent_types=Agent.transformer_agents+Agent.parser_agents
			agent_types.each do |at|
				if at.accepts?(self)
					agent=at.new(World.instance)
					begin
						agent.run(self)
						agent.process_predicates
						produced_predicates=produced_predicates+agent.produced_predicates
					rescue Exception => e
					end
				end
			end
			produced_predicates.each {|pred| pred.expand }
		end


		def to_h
			{:id => self.id, :name=>self.name, :subject=>self.subject.to_s, :object=>self.object.to_s}
		end

		def to_json
			self.to_h.to_json
		end



		def search_relevance
			@world.search_relevance(self)
		end


		def search_relevance_to_i
			rel=search_relevance
			rel=(rel*5.0).to_i
			return 4 if rel>4
			return rel 
		end 

		def was_relevant?
			return @was_relevant
		end

		def to_cutout
			return @cutout unless @cutout.nil?
			@cutout=MarkovPredicate.find_or_create_from_predicate(self)
			return @cutout
		end

		def to_chain
			@chain=MarkovPredicateChain.find_predicate_chain(self,true)
			return @chain
		end

		def single_match?(pred)
			return ((self.type==:single_fact or pred.type==:single_fact) and self.name==pred.name)
		end


		def full_match?(pred)
			return (!self.object.blank? and self.object.eql?(pred.object) and self.name==pred.name and self.type==pred.type and self.world==pred.world)
		end

		def object_match?(pred)
			if self.object.is_a?(URI) and pred.object.is_a?(URI)
				return true if ("#{self.object.to_s}/" == "#{pred.object.to_s}" or "#{self.object.to_s}" == "#{pred.object.to_s}/")
			end
			return (!self.object.blank? and self.object.eql?(pred.object) and self.world==pred.world)
		end

		def string_match?(pred)
			return (!self.object.blank? and !pred.object.blank? and !self.object.to_s.blank? and !pred.object.to_s.blank? and "#{self.object.to_s}".downcase=="#{pred.object.to_s}".downcase and self.world==pred.world)
		end

		def partial_string_match?(pred)
			return false unless (!self.object.blank? and !pred.object.blank? and self.world==pred.world)
			string1="#{self.object}".downcase
			string2="#{pred.object}".downcase
			return false unless string1.length>4 and string2.length>4
			if string1.length > string2.length
				larger=string1
				smaller=string2
			else
				larger=string2
				smaller=string1
			end
			return larger.include?(smaller)
		end
		def metaphone_match?(pred)
			return false unless (!self.object.blank? and !pred.object.blank? and self.world==pred.world)
			string1="#{self.object.to_s}".downcase
			string2="#{pred.object.to_s}".downcase
			return false if string1.length>32 or string2.length>32
			return false if string1.blank? and string2.blank?
			return (Text::Metaphone.metaphone(string1)==Text::Metaphone.metaphone(string2))
		end

		def match(pred)
			return :object_match if object_match?(pred)
			return :string_match if string_match?(pred)
			return :partial_string_match if partial_string_match?(pred)
			return :metaphone_match if metaphone_match?(pred)
			return false
		end


		def to_s
			"#{subject.class.to_s}:#{subject.to_s} #{@name.to_s} #{object.class.to_s}:#{object.to_s} #{creator.class.to_s} #{type.to_s}"
		end

		def ==(rhs)
			return (self.class==rhs.class and self.id == rhs.id)
		end

		def eql?(rhs)
			return self.==(rhs)
		end

		def short_s
			"#{subject.class.to_s}:#{subject.to_s} #{name.to_s} #{object.class.to_s}:#{object.to_s}" 
		end

		def shortest_s
			"[#{subject.to_s} #{name.to_s} #{object.to_s}]"
		end

		def hash
			(self.class.to_s+self.id.to_s).hash   
		end



	end
end
