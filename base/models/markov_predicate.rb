module Lulz
class MarkovPredicate < ActiveRecord::Base
   set_table_name :predicate_cutouts
   belongs_to :subject_type, :class_name => "ObjectType"
   belongs_to :object_type, :class_name => "ObjectType"
   belongs_to :relationship 
   belongs_to :created_by, :class_name => "ObjectType"
   belongs_to :last_profile_object_type, :class_name => "ObjectType"
   belongs_to :last_search_agent_type, :class_name => "ObjectType"
   def self.find_or_create_from_predicate(p)
      hash={}
      hash[:subject_type_id]=ObjectType.cache_find_or_create_by_name(p.subject.class.to_s).id
      hash[:object_type_id]=ObjectType.cache_find_or_create_by_name(p.object.class.to_s).id
      hash[:created_by_id]=ObjectType.cache_find_or_create_by_name(p.creator.class.to_s).id
      hash[:relationship_id]=Relationship.cache_find_or_create_by_name(p.name).id
      hash[:last_profile_object_type_id]=ObjectType.cache_find_or_create_by_name(p.last_profile_object.class.to_s).id
      hash[:last_search_agent_type_id]=ObjectType.cache_find_or_create_by_name(p.last_search_agent.class.to_s).id
      begin
			ret=MarkovPredicate.find :first, :conditions => hash
			ret=MarkovPredicate.create hash if ret.nil?
		rescue SQLite3::BusyException
			sleep 0.2
			retry
		rescue ActiveRecord::StatementInvalid
			sleep 0.2
			retry
		rescue 
		end
		return ret
   end



end
end
