module Lulz
	class BirthDate

		MONTHS=["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"]

      equality_on :birthdate
	
      def initialize(bday=nil,american=true)
			if bday.is_a? Date
				self.birthdate=bday
			elsif bday.is_a? String
				self.birthdate=BirthDate.parse(bday,american)
			end
      end


		def is_googlable?
			false
		end

		def self.parse(bday,american=true)
			day,month,year=bday.scan(/([0-9][0-9])[^0-9]([0-9][0-9])[^0-9]([0-9][0-9][0-9][0-9])/).first rescue nil
			day,month=[month,day] if american
			unless year.nil?
				return Date.civil(year.to_i,month.to_i,day.to_i) rescue nil
			end
			year,month,day=bday.scan(/([0-9][0-9][0-9][0-9])[^0-9]([0-9][0-9])[^0-9]([0-9][0-9])/).first rescue nil
			unless year.nil?
				return Date.civil(year.to_i,month.to_i,day.to_i) rescue nil
			end
			b=bday.downcase
			year=b.scan(/([0-9][0-9][0-9][0-9])/).first.first rescue nil
			return nil if year.nil?
			b.gsub(year,"")
			month=nil
			day=nil
			MONTHS.each do |m|
				unless b.scan(m).nil?
					month=MONTHS.index(m)+1
					break
				end
			end
			day=b.scan(/[0-9][0-9]/).first rescue nil
			return Date.civil(year.to_i,month.to_i,day.to_i) rescue nil
		end



	end
end
