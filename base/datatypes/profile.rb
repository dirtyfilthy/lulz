module Lulz


	class Profile
      include Datatype

      attr_writer :is_match
		attr_writer :user_match
      @@idz=0
		@@cliquez=1
      @@id_mutex=Monitor.new
      @@profiles={}
      def self.new_id(profile)
         @@id_mutex.synchronize {
            id=@@idz
            @@idz=@@idz+1

	    @@profiles[id]=profile
            return id
         }
      end

		def self.new_clique
			clique=0
			@id_mutex.syncronize {
				clique=@@cliquez
				@@cliquez=@@cliquez+1
			}
			return clique
		end

      def self.find_by_id(id)
	 return @@profiles[id.to_i]
      end

      def is_match?
         return @is_match
      end
      
      def person_id
         @person_id=Profile.new_id(self) if @person_id.nil?
         return @person_id
      end

      def to_s
	 return "TARGET" if self.class==Profile
	 return (self.respond_to?(:url) ? self.url.to_s : "")
      end



      def self.match_probabilities(profiles)
         return [] if profiles.length < 2
         matches=[]
         0.upto(profiles.length-2) do |i|
            (i+1).upto(profiles.length-1) do |j|
               m= [profiles[i], profiles[j], profiles[i].match_probability(profiles[j])]
	       m[2]=0 if m[2].nil? 
		matches << m
            end
         end
         matches.sort! { |a,b| a[2] <=> b[2] }
         return matches.reverse
         

      end

      def find_matching_predicates(b)
         matches=[]
         self._predicates.each do |pred1|
            b._predicates.each do |pred2|
               matches << [pred1, pred2] if pred1.matches? pred2
            end
         end
         return matches
      end
      
      def eql?(rhs)
	false
      end

		def indent_lines(lines,indent, indent_first=true)
			str=""
			first=true
			lines.each_line do |line|
				if first and !indent_first
					first=false
					str=str+line
					next
				end
				str=str+(" "*indent)+line
			end

			return str
		end
		alias :indent :indent_lines

      def to_text
		   path=""
			world=World.instance
			gp=world.graph_path(self)
		   gp.each { |node| path=path+"<-- [#{node.person_id}] " }
			path="<-- [0] " if path.blank? 
         path="" if self.person_id==0
			collections={}
			s="#{self.class.to_s} [#{person_id}] (#{sprintf('%.3f',world.matches[self].to_f)}) #{path}\n"
			s << indent(predicates_to_text(self),4)
			s
      end


		def predicates_to_text(obj)
			s=""
         collections={}
			obj._predicates.each do |pred|
				next if pred.object.class.archive_only? and !Blackboard.instance.options[:archive]
				collect=pred.object.class.collect_as_property
				unless collect.nil?
					collections[collect]||=[]
					collections[collect] << pred
					next
				end

				ps="#{pred.name} => "
				s << ps
				unless obj.class.sub_objects_to_a.include? pred.name
					s << pred.object.to_text << "\n"
				else	
					s << "#{pred.object.properties_to_h.inspect}\n"+indent_lines(predicates_to_text(pred.object),4,true)
				end
			end
			collections.keys.each do |c|
				ps="[#{c.to_s.upcase}] =>\n"
				options=collections[c].first.class.collect_as_options
				unless options[:order_by].nil?
					collections[c].sort!{|a,b| a.object.send(options[:order_by]) <=> b.object.send(options[:order_by])}.reverse!
					collections[c].reverse! if options[:reverse]
				end
				s<<ps
				collections[c].each do |pred|
					unless obj.class.sub_objects_to_a.include? pred.name
						s2+="#{pred.object.to_text.strip}\n"
					else 
						s2="===> #{pred.object.properties_to_h.inspect}\n"
						s2+=indent_lines(predicates_to_text(pred.object),4,true)
					end
					s<<indent_lines(s2,4,true)
				end
			end
					
         s
		end
               


	end
end
