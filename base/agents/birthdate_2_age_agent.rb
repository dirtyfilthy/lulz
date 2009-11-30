module Lulz
	class Birthdate2AgeAgent < Agent

		default_process :process
      transformer
      set_description "convert a birthday to an age"
      def self.accepts?(pred)
         return false unless (pred.object.is_a?(BirthDate))
			return false unless (pred.subject.is_a?(Profile))
			return false unless (pred.name==:date_of_birth)
         return false if is_processed?(pred)
			return true
      end



		def process(pred)
         profile=pred.subject
         birthdate=pred.object
			age=(Date.today-birthdate.birthdate).to_i/365
			pred2=single_fact_once profile, :age, Age.new(age)
			set_clique(pred,pred2) unless pred2.nil?
      end




	end
end
