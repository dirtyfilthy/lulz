class Graph
   @@mutex=Monitor.new
   Infinity=1.0/0.0
	def initialize
		@outward_arcs=Hash.new
		@inward_arcs=Hash.new
	end

	def add_edge(a,b,cost=1.0)
		@outward_arcs[a]=Hash.new if @outward_arcs[a].nil?
		@outward_arcs[a][b]=cost
		@inward_arcs[b]=Hash.new if @inward_arcs[b].nil?
		@inward_arcs[b][a]=cost

	end


	def cost(a,b)
		return @outward_arcs[a][b]
	end

	def vertices
		return (@outward_arcs.keys | @inward_arcs.keys)
	end

	def add_undirected_edge(a,b,cost=1.0)
		add_edge(a,b,cost)
		add_edge(b,a,cost)
	end

	def neighbours(a)
		return [] if @outward_arcs[a].nil?
		return @outward_arcs[a].keys
	end

	def delete_undirected_edge(a,b)
	    delete_edge(a,b)
	    delete_edge(b,a) 
        end

	def delete_edge(a,b)
	    @outward_arcs[a].delete(b) rescue nil
	    @inward_arcs[b].delete(a) rescue nil
        end

	# Dijkstra's shortest path algorithm
	
	def shortest_paths(start)
		nodes=vertices
		dist=Hash.new
		prev=Hash.new
		vertices.each do |v|
			dist[v]= +Infinity
			prev[v]=nil
		end
		dist[start]=0
		unvisited=vertices.clone
		while !unvisited.empty? do
			min= +Infinity
			shortest=nil
			unvisited.each do |u|
				if dist[u]<min
					min=dist[u]
					shortest=u
				end
			end
			u=shortest
			unvisited.delete(u)
			(neighbours(u) & unvisited).each do |n|
				next if dist[u].nil? or dist[n].nil?
				alt=dist[u]+cost(u,n)
				if alt<dist[n]
					dist[n]=alt
					prev[n]=u
				end
			end
		end
		return [prev,dist]
	end

	# modified Dijkstra to find most likely markov chain between two nodes

	def probabalistic_shortest_paths(start)
		nodes=vertices
		dist=Hash.new
		prev=Hash.new
		vertices.each do |v|
			dist[v]=+Infinity
			prev[v]=nil
		end
		dist[start]=1.0
		unvisited=vertices.clone
		while !unvisited.empty? do
			min= +Infinity
			shortest=nil
			unvisited.each do |u2|
				next if dist[u2].nil?
				if dist[u2]<min
					min=dist[u2]
					shortest=u2
				end
			end
			u=shortest
			unvisited.delete(u)
			(neighbours(u) & unvisited).each do |n|
				alt=dist[u]*cost(u,n)
				if alt<dist[n]
					dist[n]=alt
					prev[n]=u
				end
			end
		end
		return [prev,dist]
	end


end
