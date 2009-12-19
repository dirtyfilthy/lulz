require "#{LULZ_DIR}/base/datatypes/analysis/post.rb"

module Lulz
	class TwitterPost < Post

		properties :source,:in_reply_to 
		attr_accessor :contents
	
      def initialize(canoniacal=nil)
         self.canonical_url=canoniacal 
      end

		def to_s
			return @contents
		end

	end
end
