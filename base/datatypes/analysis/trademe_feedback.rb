require "#{LULZ_DIR}/base/datatypes/analysis/post.rb"

module Lulz
	class TrademeFeedback

		properties :feedback_from,:feedback_type

		attr_accessor :contents
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
