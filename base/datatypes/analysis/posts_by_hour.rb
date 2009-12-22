module Lulz
	class PostsByHour
		properties :hour
		collect_as :posts_by_hours,:order_by => :hour, :reverse => true
		equality_on :hour	
		attr_accessor :num
		def initialize(w)
			@num=w
		end
		

		def to_s
			return @num.to_s
		end

	end
end
