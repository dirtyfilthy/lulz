module Lulz
	class ExtractTldAgent < Agent

		default_process :process
		transformer
		set_description "extract a two letter tld from country, email, or url"
		def self.accepts?(pred)
			return false unless pred.object.is_a?(Country) or pred.object.is_a?(EmailAddress) or pred.object.is_a?(URI)
			return false unless pred.subject.is_a?(Profile)
			return false if pred.object.is_a?(URI) and pred.object.host =~ /(identi\.ca|last\.fm)$/
			return false if is_processed?(pred)
			return true
		end



		def process(pred)
			set_processed(pred)
			object=pred.object
			tld=nil
			case object.class.to_s
			when "Lulz::Country"
				tld=object.to_cc
			when "Lulz::EmailAddress"
				tld=object.to_s.scan(/\.([a-z][a-z])$/).first.first  rescue nil
			when "URI::HTTP"
				tld=object.host.to_s.scan(/\.([a-z][a-z])$/).first.first  rescue nil
			end
			return if tld.nil?
			tld=tld.downcase
			pred2=brute_inference_once pred.subject, :extracted_tld, tld
			set_clique(pred,pred2) unless pred2.nil?
		end




	end
end
