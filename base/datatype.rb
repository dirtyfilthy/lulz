module Lulz
	module Datatype
		@@properties=[]

		def self.included(base)
			base.extend(ClassMethods)  
		end

		attr_writer :_lulz_unclean


		def to_text
			p=self.properties_to_h
			s=""
			s="#{p.inspect} " unless p=={}
			s=s+self.to_s
		end

		def _lulz_unclean?
			return false if @_lulz_unclean.nil?
			return @_lulz_unclean
		end

		def archive_only?
			false
		end

		def _world
			World.instance
		end

		def _world=(w)
		end

		def equality_s
			self.to_s
		end

		def _cleanse!
			raise RuntimeError, "World is uninitialised!" if self._world.nil?
			self._world.clean(self)
		end   

		def _query(type,options)

			# this is incredibly inefficent

			predicates=self._predicates
			results=[] if type==:all
			predicates.each do |predicate|
				if predicate.name==options[:predicate]
					return predicate if type==:first
					results << predicate
				end
			end
			return results if type==:all
			return nil
		end

		def _query_object(type,options)
			result=_query(type,options)
			return nil if result.nil?
			return result.object if type==:first
			return result.map{|predicate| predicate.object}
		end

		def self.define_attr_method(name, value)
			singleton_class.send :alias_method, "original_#{name}", name rescue nil
			singleton_class.class_eval do
				define_method(name) do
					value
				end
			end
		end


		def _predicate(options)
			raise RuntimeError, "World is uninitialised! #{self.inspect}" if self._world.nil?
			p=Lulz::Predicate.new
			p.subject=self
			p.object=options[:object]
			p.name=options[:name]
			p.world=self._world
			p.creator=options[:creator]
			p.probability=options[:probability]
			p.type=options[:type]
			p1=self._world.add_predicate p
			return p1
		end

		def _predicates()
			raise RuntimeError, "World is uninitialised! #{self}" if self._world.nil?
			return self._world.predicates_by_subject(self)
		end

		def _predicates_as_object
			raise RuntimeError, "World is uninitialised! #{self}" if self._world.nil?
			return self._world.predicates_by_object(self)
		end

		def _attribute(name,value)
			self._predicate :name => name, :object => value, :probability => P_TRUE
		end

		def _attributes
			raise RuntimeError, "World is uninitialised!" if self._world.nil?
			predicates=self._world.predicates_by_subject(self)
			attributes=Hash.new
			predicates.each { |k, v| attributes[k]=v.object }
			return attributes
		end


			def properties_to_h
					
			h={}
			self.class.properties_to_a.each do |property|
				h[property]=self.send(property)
			end
			return h
			end


		module ClassMethods


			def properties_to_a
				[]
			end

			def collect_as_property
				nil
			end

			def collect_as_options
				{}
			end

			def archive_only
				module_eval("def self.archive_only?; return true; end")
			end

			def properties(*attrs)
			props=self.properties_to_a
			attrs.each do |attr|	
		
			code = <<CODE
			attr_accessor :#{attr}
CODE
	
			module_eval(code)
			

		end
		
			code = <<CODE
			def self.properties_to_a
				#{(props+attrs).uniq.inspect}
			end
CODE
			module_eval(code)
			end

			def collect_as(name,options={})
				code = <<CODE
				def self.collect_as_property
					#{name.inspect}
				end

				def self.collect_as_options
					#{options.inspect}
				end
CODE
		module_eval(code)

	end

			

			def equality_on(attr)
				code = <<CODE

		attr_accessor :#{attr}

			def to_s
				return self.#{attr}.to_s
			  end


				def eql?(rhs)
					return (rhs.is_a?(self.class) and self.#{attr}==rhs.#{attr})
				end

				def ==(rhs)
					return self.eql?(rhs)
				end      


				def hash
				 return (self.class.to_s+self.#{attr}.to_s).hash
			end

			def equality_s
				return self.#{attr}
			end

		def empty?
			return self.#{attr}.blank?
		end

CODE
	
	module_eval(code)

	end
	end
end
end
