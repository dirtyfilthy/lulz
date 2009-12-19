require 'optparse'
require 'ostruct'
require 'uri'
require 'builder'
module Lulz
	module CLI

		def self.parse_options(blackboard)

			orig_options = YAML::load_file("#{LULZ_DIR}/config/defaults.yml")
			options=orig_options.clone
			options[:disabled_agents]||=[]
			blackboard.options=options
			world=blackboard.world
			person=nil 
			ua=Lulz::UserAgent.new(world)
			@opts=nil
			OptionParser.new do |opts|
				opts.banner = "lulz V#{Lulz::VERSION} by alhazred ;)"
				opts.separator " "
				opts.separator "General options:"
				opts.on "-M","--match-mode",Float,"turn on match training mode" do |t|
					options[:match_mode]=true
					options.merge!(orig_options[:match_mode_settings])

				end
				opts.on "-S","--rebuild-strategy", "rebuild markov search strategy and exit (might take hours)" do
					Lulz::MarkovPredicateChain.run_stochastic
					exit
				end

				opts.on "-L","--list", "list agents and exit" do
					list
					exit
				end

				opts.on "-P" , "--summary", "preface with summary" do
					options[:summary]=true
				end


				opts.on "-s","--search-threshold THRESHOLD",Float,"set search threshold i.e. 0.2" do |t|
					options[:search_threshold]=t
				end
				opts.on "-m","--match-threshold THRESHOLD",Float,"set match threshold i.e. 0.4" do |t|
					options[:match_threshold]=t
				end
				opts.on "-g","--graph-cutoff THRESHOLD", Float, "set threshold to recalculated graph i.e. 0.3" do |t|
					options[:graph_cutoff]=t
				end


				opts.on "-t","--threads THREADS",Integer,"max number of child threads" do |t|
					options[:threads]=t
				end

				opts.on "-F", "--fast-search", "turn on fast search options (specified in config/defaults.yml)" do 
					options.merge!(orig_options[:fast_search_settings])
				end

				opts.on "-T","--timeout SECONDS",Integer,"stop search after SECONDS (0 for no timeout)" do |t|
					options[:timeout]=t
				end

				opts.on "-H","--hard-timeout SECONDS",Integer,"hard stop search after SECONDS (0 for no timeout)" do |t|
					options[:hard_timeout]=t
				end


				opts.on "-d","--disable-agent AGENT", "disable this agent from running, i.e. -d GoogleSearchAgent" do |agent|

					options[:disabled_agents].push(agent).uniq!
				end

				opts.on "-e","--enable-agent AGENT", "enable this agent, i.e. -e GoogleSearchAgent" do |agent|
					options[:disabled_agents].delete(agent)
				end


				opts.on "-X","--xml", "run silently and output xml (also works in analysis mode)" do 
					options[:xml]=true
					options[:silent]=true
				end

				opts.on "-A","--analyze URL", "expand and analyze url" do |url|
					
					options[:expanded]=true
					options[:match_threshold]=0.0
					url="http://#{url}" unless url =~ /^http/
					u=URI.parse(url)

					expander=Lulz::ExpanderAgent.new(Lulz::World.instance)

					expander.expand(u)
					person=Lulz::World.instance.profiles.first
						
					blackboard.user_write(person)
					analyzer=Lulz::AnalyzerAgent.new(Lulz::World.instance)
					analyzer.analyze(person)
					Lulz::World.instance.recalc_all
				end

				opts.separator " "
				opts.separator "Target information:"
				opts.on "--expand-as-target URL", "expand URL and set as target, must be used BEFORE other target info" do |url|
					unless person.nil?
						puts "Target info already set!"
						exit 1
					end
					url="http://#{url}" unless url =~ /^http/
					u=URI.parse(url)
					expander=Lulz::ExpanderAgent.new(Lulz::World.instance)
					expander.expand(u)
					person=Lulz::World.instance.profiles.first
					blackboard.user_write(person) unless person.nil?
				end	       
				opts.on "--email ADDRESS","specify target email address" do |email|
					if person.nil?
						person=Lulz::Person.new
						blackboard.user_write(person)
					end
					ua.brute_fact person, :email, Lulz::EmailAddress.new(email)
				end
				opts.on "--alias ALIAS","specify target alias or username" do |al|

					if person.nil?
						person=Lulz::Person.new
						blackboard.user_write(person)
					end
					ua.brute_fact person, :alias, Lulz::Alias.new(al)
				end
				opts.on "--name NAME","specify target name" do |name|

					if person.nil?
						person=Lulz::Person.new
						blackboard.user_write(person)
					end
					ua.brute_fact person, :name, Lulz::Name.new(name)
				end
				opts.on "--age AGE","specify target age" do |age|

					if person.nil?
						person=Lulz::Person.new
						blackboard.user_write(person)
					end
					ua.single_fact person, :age, Lulz::Age.new(age)
				end


				opts.on "--sex SEX","specify target sex (male|female)" do |sex|

					if person.nil?
						person=Lulz::Person.new
						
						blackboard.user_write(person)
					end
					ua.single_fact person, :sex, Lulz::Sex.new(sex)
				end
				opts.on "--country COUNTRY","specify target country" do |country|

					if person.nil?
						person=Lulz::Person.new
						blackboard.user_write(person)
					end
					ua.single_fact person, :country, Lulz::Country.new(country)
				end
				opts.on "--city CITY","specify target city" do |city|

					if person.nil?
						person=Lulz::Person.new
						blackboard.user_write(person)
					end
					ua.single_fact person, :city, Lulz::Locality.new(city)
				end
				opts.on "--keyword KEYWORD","specify target keyword" do |keyword|

					if person.nil?
						person=Lulz::Person.new
						blackboard.user_write(person)
					end
					ua.brute_fact person, :keyword, keyword
				end
				opts.on "--homepage URL","specify target URL" do |url|

					if person.nil?
						person=Lulz::Person.new
						blackboard.user_write(person)
					end

					url="http://#{url}" unless url =~ /^http/
					u=URI.parse(url)
					ua.brute_fact person, :homepage_url, u
				end
				opts.separator " "
				opts.separator "Analysis options:"
				opts.on "-r","--archive","dump all posts, tweets, etc" do
					options[:archive]=true
					
				end	
				opts.separator " "
				opts.separator "Debugging and fine grained control options:"
				opts.on "--single-thread","execute within a single thread for profiling" do
					options[:single_thread]=true
				end
				opts.on "--expand URL","expand URL, perform identity resolution and exit" do |url|
					options[:expanded]=true
					options[:match_threshold]=0.0
					url="http://#{url}" unless url =~ /^http/
					u=URI.parse(url)

					expander=Lulz::ExpanderAgent.new(Lulz::World.instance)

					expander.expand(u)
					if person.nil?
						person=Lulz::World.instance.profiles.first
						blackboard.user_write(person)
					end
					Lulz::World.instance.recalc_all
				end

				opts.on "--run-agent AGENT", "run AGENT on profile(s), expand, exit. can be chained with --expand" do |agent|
					ag_class=Agent.agents.select{|a| a.to_s=="Lulz::#{agent}"}.first rescue nil
					if ag_class.nil?
						puts "Agent '#{agent}' not found!"
						exit 1
					end
					options[:run_agent]||=[]
					options[:run_agent] << ag_class
				end



				opts.separator " "
				opts.on_tail("-h", "--help", "Show this message") do
					puts opts
					exit
				end

				@opts=opts.to_s
			end.parse!

			if person.nil? and not options[:expanded] and not options[:run_agent]
				puts @opts
				exit
			end
			ua.process_predicates
			if options[:run_agent]

				produced_predicates=[]
				options[:run_agent].each do |ag_class|
					world=World.instance
					world.predicates.each do |pred|
						agent=ag_class.new(world)
						agent.run(pred) if ag_class.accepts?(pred)
						produced_predicates=produced_predicates+agent.produced_predicates
					end
				end
				produced_predicates.each do |pred|
					pred.expand
				end
				Lulz::World.instance.recalc_all

			end	    


			if options[:expanded]
				person._predicates.each{|pred| pred.expand }
			end
			options[:disabled_agents].map! { |klass| Lulz.const_get("#{klass}") }
			blackboard.options=options

		end

		def self.list
			puts
			agents=Agent.agents
			searchers=Agent.searcher_agents.sort { |a,b| a.to_s <=> b.to_s }
			transformers=Agent.transformer_agents.sort { |a,b| a.to_s <=> b.to_s }
			analyzers=Agent.analyzer_agents.sort { |a,b| a.to_s <=> b.to_s }
			parsers=Agent.parser_agents.sort { |a,b| a.to_s <=> b.to_s }
			others=(agents-searchers-transformers-parsers-analyzers).sort { |a,b| a.to_s <=> b.to_s }
			puts "   SEARCH AGENTS:"
			searchers.each { |agent| puts "      #{agent.to_s.gsub("Lulz::","").ljust(25)[0..24]} - #{agent.description}" }
			puts
			puts "   PARSER AGENTS:"
			parsers.each { |agent| puts "      #{agent.to_s.gsub("Lulz::","").ljust(25)[0..24]} - #{agent.description}" }
			puts 
			puts "   TRANSFORMER AGENTS:"
			transformers.each { |agent| puts "      #{agent.to_s.gsub("Lulz::","").ljust(25)[0..24]} - #{agent.description}" }
			puts
			puts "   ANALYZER AGENTS:"
			analyzers.each { |agent| puts "      #{agent.to_s.gsub("Lulz::","").ljust(25)[0..24]} - #{agent.description}" }
			puts
			puts "   OTHER AGENTS:"
			others.each { |agent| puts "      #{agent.to_s.gsub("Lulz::","").ljust(25)[0..24]} - #{agent.description}" }
		end

		def self.summary(bb)
			world=World.instance
			matches=world.matches
			match_threshold=bb.options[:match_threshold]
			predicates={}
			profiles=world.sorted_profiles.select { |p| matches[p].to_f > match_threshold }
			puts
			puts "SUMMARY:"
			puts
			puts "   PROFILES:"
			profiles.each do |p|
				puts "      [#{p.person_id.to_s.rjust(3)}] (#{sprintf('%.3f',matches[p].to_f)}) - #{p.to_s}"
				p._predicates.each do |pred|
					next if pred.name==:profile_url
					next if pred.name==:bio 
					next if pred.name==:linkedin_url
					next if pred.name==:blogspot_profile_url
					next if pred.type==:brute_inference
					predicates[pred.name]||=[]
					predicates[pred.name]<<pred.object
				end
			end
			puts 
			puts "   DETAILS:"
			predicates.each_key do |key|
				print "      #{key.to_s.ljust(15)} : "
				predicates[key].uniq.each do |obj|
					subjs=world.predicates_by_object(obj).select {|pred| profiles.include?(pred.subject)}.map{ |m| m.subject }.uniq
					print " #{obj} [#{subjs.map { |pro| pro.person_id}.join(',')}]"
				end
				puts
			end
			puts 
			puts


		end	 





		def self.ask_matches(bb)
			sure="no"
			user_matches=""
			while sure!="yes"
				puts "Enter matches"
				print "> "
				STDOUT.flush
				user_matches=STDIN.gets.strip+" 0"
				puts "You entered: '#{user_matches}', type 'yes' to continue"
				print "> "
				STDOUT.flush
				sure=STDIN.gets.strip
			end
			profiles_hash={}
			idz=[]
			nonmatches=[]
			matches=[]
			profiles=bb.profiles
			profiles.each do |profile|
				profiles_hash[profile.person_id.to_s]=profile
				idz << profile.person_id.to_s
			end
			split_match=user_matches.split(" ").uniq
			split_match.each {|m| profiles_hash[m].user_match=true}
			pp split_match
			pp user_matches 
			pp split_match 
			0.upto(split_match.length-2) do |current|
				(current+1).upto(split_match.length-1) do |match|
					matches <<  [split_match[current],split_match[match]]
				end
			end
			split_nonmatch=idz - split_match
			0.upto(split_match.length-1) do |current|
				0.upto(split_nonmatch.length-1) do |match|
					nonmatches <<  [split_match[current],split_nonmatch[match]]
				end
			end 

			split_match.flatten.uniq.each do |m| 
				profiles_hash[m].is_match=true
			end

			split_nonmatch.flatten.uniq.each do |m| 
				profiles_hash[m].is_match=false
			end

			matches.each do |match|
				puts "saving match #{match[0]} #{match[1]}"
				profile1=profiles_hash[match[0]]
				profile2=profiles_hash[match[1]]
				IdentityBayes.save_match(profile1,profile2,true) 
			end


			nonmatches.each do |nonmatch|
				puts "saving nonmatch #{nonmatch[0]} #{nonmatch[1]}"
				profile1=profiles_hash[nonmatch[0]]
				profile2=profiles_hash[nonmatch[1]]
				IdentityBayes.save_match(profile1,profile2,false)
			end 

			bb.save_predicate_statistics




		end

		def self.predicates_to_xml(xml,obj)
		
					collections={}
					obj._predicates.each do |predicate|
						
						next if predicate.object.class.archive_only? and !Blackboard.instance.options[:archive]
						collect=predicate.object.class.collect_as_property
						unless collect.nil?
							collections[collect]||=[]
							collections[collect] << predicate
							next
						end
						klass=predicate.object.class.to_s
						klass.gsub!(/[A-Za-z]+::/,"")
						xml.predicate(:relationship => predicate.name.to_s, :creator => predicate.creator.class.to_s.gsub("Lulz::",""),:type=>predicate.type.to_s){
														
									unless obj.class.sub_objects_to_a.include? predicate.name
										xml.tag!(klass.underscore.to_sym,predicate.object.properties_to_h,predicate.object.to_s)
									else
										xml.tag!(klass.underscore.to_sym,predicate.object.properties_to_h){
											xml.predicates {
												predicates_to_xml(xml,predicate.object)
											}
										}
									end
						}

					end
					collections.keys.each do |c|
						ps="   [#{c.to_s.upcase}] =>\n"
						options=collections[c].first.object.class.collect_as_options
						unless options[:order_by].nil?
							collections[c].sort!{|a,b| a.object.send(options[:order_by]) <=> b.object.send(options[:order_by])}.reverse!
							collections[c].reverse! if options[:reverse]
						end
						xml.tag!(c.to_s){
							collections[c].each do |predicate|
								klass=predicate.object.class.to_s
								klass.gsub!(/[A-Za-z]+::/,"")
								xml.predicate(:relationship => predicate.name.to_s, :creator => predicate.creator.class.to_s.gsub("Lulz::",""),:type=>predicate.type.to_s){
									unless obj.class.sub_objects_to_a.include? predicate.name
										xml.tag!(klass.underscore.to_sym,predicate.object.properties_to_h,predicate.object.to_s)
									else
										
										xml.tag!(klass.underscore.to_sym,predicate.object.properties_to_h){
											xml.predicates {
												predicates_to_xml(xml,predicate.object)
											}
										}
									end
								}
							end
						}
					end
		end
		
		
		def self.to_xml
			$KCODE = 'UTF8'
			out=""
			xml = Builder::XmlMarkup.new(:target=>out, :indent => 2)
			xml.instruct!(:xml, :encoding => "UTF-8")
			xml.profiles {
				World.instance.profiles.sort{|a,b| a.person_id <=> b.person_id}.each do |profile|
				xml.profile(:id => profile.person_id, :score => sprintf('%.3f',World.instance.matches[profile].to_f), :type=> profile.class.to_s.gsub("Lulz::","")) {
					xml.graph_path {
					World.instance.graph_path(profile).each do |path|
					xml.profile(:id=>path.person_id)
					end
				}
				xml.predicates {
					predicates_to_xml(xml,profile)
				}
			}	
		end
		}

		puts out
		end
		
	end
end
