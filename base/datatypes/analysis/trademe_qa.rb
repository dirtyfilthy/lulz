require "#{LULZ_DIR}/base/datatypes/analysis/post.rb"

module Lulz
	class TrademeQA

		
		collect_as :questions
		properties :asked_by
		def to_s
			@contents.to_s
		end
		def equality_s
			never
		end

      def eql?(rhs)
			false
		end	
	end
end
