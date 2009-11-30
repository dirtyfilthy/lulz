module Lulz


	class Profile
      include Datatype

      attr_writer :is_match

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

      def to_text
		   path=""
			world=World.instance
			gp=world.graph_path(self)
		   gp.each { |node| path=path+"<-- [#{node.person_id}] " }
			path="<-- [0] " if path.blank? 
         path="" if self.person_id==0
			s="#{self.class.to_s} [#{person_id}] (#{sprintf('%.3f',world.matches[self].to_f)}) #{path}\n"
         self._predicates.each do |pred|
            s << "   #{pred.name} => #{pred.object.to_s}\n"
         end
         s
      end

               


	end
end
