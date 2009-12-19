module Lulz
	class Zeitgeist
		collect_as :zeitgeist,:order_by => :num_words
		properties :num_words 
		attr_accessor :word	

		def initialize(w)
			@word=w
		end

		def to_s
			return @word
		end

	end
end
