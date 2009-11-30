require 'inline'
require 'ruby_to_ansi_c'
module Inline
class Ruby < Inline::C
   def initialize(mod)
     super
      end

   def optimize(meth)
    src = RubyToAnsiC.translate(@mod, meth)
     @mod.class_eval "alias :#{meth}_slow :#{meth}"
     @mod.class_eval "remove_method :#{meth}"
     c src
   end
end
end


module Lulz

   class ProxyCount
      attr_accessor :same_person_count
      attr_accessor :different_person_count
      
      def total_count
      	return self.same_person_count+self.different_person_count
      end
 
   end

   class PersonMatchResult < ActiveRecord::Base
      @@record_cache={} 
      @@total_cache={}     
      def total_count
      	return self.same_person_count+self.different_person_count
      end
      
      def self.find_count_record(pred1, pred2)
         h=match_hash(pred1,pred2)
         return @@record_cache[h] if @@record_cache.key?(h)
         count_rec=self.find :first, :conditions => h 
         count_rec=self.create!(h) if count_rec.nil?
         @@record_cache[h]=count_rec
         return count_rec
      end

      def self.find_broad_count(pred1, pred2)
         h=match_hash(pred1,pred2)
         h.delete(:profile_type_1)
         h.delete(:profile_type_2)
         h.delete(:creator_1)
         h.delete(:creator_2)
         return @@record_cache[h] if @@record_cache.key?(h)
         count_recs=self.find :all, :conditions => h
         proxy=ProxyCount.new
         proxy.same_person_count=0
         proxy.different_person_count=0
         count_recs.each do |rec|
            proxy.same_person_count=proxy.same_person_count+rec.same_person_count
            proxy.different_person_count=proxy.different_person_count+rec.different_person_count
         end
         @@record_cache[h]=proxy   
         return proxy
      end





      def self.find_total_match_count(pred1, pred2)

         h={}
         type_1=pred1.subject.class.to_s
         type_2=pred2.subject.class.to_s
         h[:predicate_1]="**TOTALMATCH"
         if type_1 < type_2
            h[:profile_type_1]=type_1
            h[:profile_type_2]=type_2
         else
            h[:profile_type_1]=type_2
            h[:profile_type_2]=type_1
         end
         return @@total_cache[h] if @@total_cache.key?(h) 
         rec=self.find :first, :conditions => h
         rec=self.create!(h) if rec.nil?
         @@total_cache[h]=rec
         return rec

      end




      def self.find_total_count
         h={:predicate_1 => "**TOTAL"}
         return @@total_cache[h] if @@total_cache.key?(h)
         rec=self.find :first, :conditions => h
         rec=self.create!(h) if rec.nil?
         @@total_cache[h]=rec
         return rec

      end

      def self.find_total_predicate_count_record
         h={:predicate_1 => "**TOTALPRED"}
          return @@total_cache[h] if @@total_cache.key?(h)
         rec=self.find :first, :conditions => h
         rec=self.create!(h) if rec.nil?
         @@total_cache[h]=rec
         return rec

      end


      def self.add_match_records(person1,person2,person_match)

         # brute force search ;_; (i iz lazy)
         total_count=self.find_total_count
         total_match_count=self.find_total_match_count(person1._predicates.first,person2._predicates.first)
         if person_match
            total_count.same_person_count=total_count.same_person_count+1
            total_match_count.same_person_count=total_match_count.same_person_count+1
         else
            total_count.different_person_count=total_count.different_person_count+1
            total_match_count.different_person_count=total_match_count.different_person_count+1
         end
         total_count.save!
         total_match_count.save!
         matches={}
         person1._predicates.each do |pred1|
            person2._predicates.each do |pred2|
               next if pred1.object.blank? or pred2.object.blank?
               h=match_hash(pred1,pred2)
               if pred1.match(pred2) or pred1.single_match?(pred2)
                  matches[h]=[pred1,pred2,person_match]
               end
               
            end
         end
         matches.each_value do |to_add|
            add_predicate_match(*to_add)
         end
         
      end

      def self.calculate_match(person1, person2)
         total_count=self.find_total_count
         posterior=total_count.same_person_count.to_f/(total_count.same_person_count+total_count.different_person_count) rescue Lulz::P_FALSE
         posterior=1/10000 if posterior.nil? or posterior.nan?
	 pred_queue=[]

	 person1._predicates.each do |pred1|
            next if pred1.object.blank?
            person2._predicates.each do |pred2|
               next if pred2.object.blank?
               poss_posterior=match_prob_from_evidence(0.5,pred1,pred2)
	            
               pred_queue << [poss_posterior, pred1, pred2]
            end
         end
	 pred_queue.sort! { |a,b| (a[0]*(a[1].single_match?(a[2])?100:1)) <=> (b[0]*(b[1].single_match?(b[2])?100:1)) }
    while match=pred_queue.pop
	   match_objs=[match[1].object,match[2].object]
	   posterior=match_prob_from_evidence(posterior,match[1],match[2])
      pred_queue=pred_queue.delete_if { |item| match_objs.include?(item[1].object) or match_objs.include?(item[2].object) }
	end
         return posterior

      end

      def self.update_match(person1, person1_prior, person1_predicates, person2)
         total_count=self.find_total_count
         posterior=person1_prior
         posterior=total_count.same_person_count.to_f/(total_count.same_person_count+total_count.different_person_count) rescue Lulz::P_FALSE if posterior.nil?
         posterior=1/10000 if posterior.nil? or posterior.nan?
         pred_queue=[]
	 person1_predicates.each do |pred1|
            next if pred1.object.blank?
            person2._predicates.each do |pred2|
               next if pred2.object.blank?
	       poss_posterior=match_prob_from_evidence(0.5,pred1,pred2)
	       pred_queue << [poss_posterior, pred1, pred2]
            end
         end
	pred_queue.sort! { |a,b| (a[0]*(a[1].single_match?(a[2])?100:1)) <=> (b[0]*(b[1].single_match?(b[2])?100:1)) }
	while match=pred_queue.pop
	   posterior=match_prob_from_evidence(posterior,match[1],match[2])
	   pred_queue.delete_if { |item| match.include?(item[1].object) or match.include?(item[2].object) }
	end
         return posterior
      end


      def self.pred_likelyhoods(pred1,pred2)
	      pred_count=self.find_count_record(pred1,pred2)
         total_count=self.find_total_match_count(pred1,pred2)
         if pred_count.total_count<20
             pred_count=self.find_broad_count(pred1, pred2)
             total_count=self.find_total_count
         end 
     	   if pred_count.total_count<20
            if (pred1.match(pred2) and !pred1.single_match?(pred2)) or (pred1.single_match?(pred2) and pred1.match(pred2)==:object_match)
	      	   pred_count=ProxyCount.new
		         pred_count.same_person_count=100
		         pred_count.different_person_count=50
		         total_count=ProxyCount.new
		         total_count.same_person_count=100
		         total_count.different_person_count=150
            else
               pred_count=ProxyCount.new
		         pred_count.same_person_count=1
		         pred_count.different_person_count=500
		         total_count=ProxyCount.new
		         total_count.same_person_count=1000
		         total_count.different_person_count=1500
            end   
	      end
	      pred_given_person=pred_count.same_person_count.to_f/total_count.same_person_count rescue Lulz::P_FALSE
         pred_given_person=Lulz::P_FALSE if pred_given_person.nil? or pred_given_person.nan?
         pred_given_not_person=pred_count.different_person_count.to_f/total_count.different_person_count rescue Lulz::P_FALSE
         pred_given_not_person=Lulz::P_FALSE if  pred_given_not_person.nil? or pred_given_not_person.nan?
         return [pred_given_person, pred_given_not_person]
      end

      def self.match_prob_from_evidence(prior,pred1,pred2)
         return prior unless (pred1.match(pred2)  or pred1.single_match?(pred2))
	      pred_given_person, pred_given_not_person = pred_likelyhoods(pred1,pred2)
         prior=Lulz::P_FALSE if prior==0
	 prior=LULZ::P_TRUE if prior==1
      posterior=(pred_given_person*prior)/((pred_given_person*prior)+(pred_given_not_person*(1-prior)))
	      if posterior.nil? or posterior.nan?
	 	      return prior
	      end
         return posterior 
         
      end




      
      def self.add_predicate_match(pred1,pred2,person_match)
         count_record=self.find_count_record pred1, pred2
         total_pred_rec=self.find_total_predicate_count_record
         if person_match
            total_pred_rec.same_person_count=total_pred_rec.same_person_count+1
            count_record.same_person_count=count_record.same_person_count+1
            count_record.save!
            total_pred_rec.save!
         else
            total_pred_rec.different_person_count=total_pred_rec.different_person_count+1
            count_record.different_person_count=count_record.different_person_count+1
            count_record.save!
            total_pred_rec.save!
         end
      end

      private

      def self.order(pred1, pred2)
         return [pred2, pred1] if pred1.name.to_s > pred2.name.to_s
         return [pred1, pred2] if pred2.name.to_s > pred1.name.to_s
         return [pred2, pred1] if pred1.subject.class.to_s > pred2.subject.class.to_s
         return [pred1, pred2] if pred1.subject.class.to_s < pred2.subject.class.to_s
         return [pred2, pred1] if pred1.creator.to_s > pred2.creator.to_s
         return [pred1, pred2] if pred1.creator.to_s < pred2.creator.to_s
         return [pred2, pred1] if pred1.object.class.to_s > pred2.object.class.to_s
         return [pred1, pred2]
      end

      def self.match_hash(pred1, pred2)
         pred1, pred2 = order(pred1,pred2)
         h={}
         h[:creator_1]=pred1.creator.class.to_s
         h[:creator_2]=pred2.creator.class.to_s
         h[:datatype_1]=pred1.object.class.to_s
         h[:datatype_2]=pred2.object.class.to_s
         h[:predicate_1]=pred1.name.to_s
         h[:predicate_2]=pred2.name.to_s
         h[:single_fact]=pred1.single_match?(pred2)
         h[:match_type]=pred1.match(pred2).to_s
         h[:match_type]=(pred1.match(pred2)==:object_match) if h[:single_fact]
         h[:profile_type_1]=pred1.subject.class.to_s
         h[:profile_type_2]=pred2.subject.class.to_s
         return h
      end 
      


   end

end




