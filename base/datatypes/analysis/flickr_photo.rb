module Lulz
	class FlickrPhoto 

		
		properties :photo_id, :tags, :latitude, :longitude, :date_taken, :date_uploaded
		equality_on :photo_id
		

      def initialize(photo_id)
         self.photo_id=photo_id
      end

		def to_s
			return @contents
		end

	end
end
