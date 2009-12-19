module Lulz
   class TrademeProfile < Profile
	   equality_on :member_id
		sub_objects :auction
	end
end
