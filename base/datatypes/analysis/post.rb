module Lulz
	class Post
		collect_as :posts,:order_by => :posted_at
		archive_only
      equality_on :canonical_url
		properties :posted_at, :subject 
		attr_accessor :contents
	
      def initialize(canoniacal=nil)
         self.canonical_url=canoniacal 
      end

		def to_s
			return @contents
		end

	end
end
