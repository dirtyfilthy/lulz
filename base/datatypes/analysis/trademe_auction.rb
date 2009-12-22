require "#{LULZ_DIR}/base/datatypes/analysis/post.rb"

module Lulz
	class TrademeAuction 

		properties :id,:closed_at,:as 
		sub_objects :question
		equality_on :id
		archive_only	

	end
end
