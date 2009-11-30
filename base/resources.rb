require 'ostruct'
require 'yaml'
module Lulz
   class Resources
      @@resources=YAML::load_file("#{LULZ_DIR}/config/resources.yml")

      def self.method_missing(m, *args)
         method=m.to_s

         # i.e. get_twitter_account

         if method =~ /^get_/
            resource_type = method.gsub(/^get_/,"")
            list=@@resources["#{resource_type}s".to_sym]
            r=OpenStruct.new(list[rand(list.length)]) rescue nil
            return r
         end
      end

   end
end
