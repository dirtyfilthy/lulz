require 'pp'
require 'timeout'
require 'ostruct'

# alhazred's confabulous & very limited whois library

WHOIS_BIN="/usr/bin/whois"




module Whois
   
   @@handlers={}

   def self.define_handler(*domainz, &handler)
      domainz.flatten!
      domainz.each { |domain| @@handlers[domain]=handler }

   end


   define_handler(".co.nz", ".net.nz", ".org.nz", ".govt.nz", ".geek.nz", ".maori.nz") { |record|
      raw=record["raw_data"]
      a=raw.scan(/([a-z_-]+): (.*)/)
      a.each { |field|
	 key, value = field
         record[key.strip]=value.strip
      }
   
   }


   def self.generic_handler(record)
      raw=record["raw_data"]
      a=raw.scan(/(.*):(.*)/)
      a.each do |f|
	 key, value = f
	 
	 key.strip!
	 value.strip!
	 type=nil
	 type="registrant" if key.downcase =~ /registrant/
	 type="technical" if key.downcase =~ /tech/
	 type="admin" if key.downcase =~ /admin/
	 
	 field=["phone","email","name","city","country"].select{|i| key.downcase.include?(i) }.first
	 record["#{type}_contact_#{field}"]=value unless field.nil? or value.nil? or type.nil? or record.key?("#{type}_contact_#{field}")
      end


   end

   def self.whois_domain(domain)
      tld=domain.scan(/\.[a-z]+$/).first rescue nil
      return "" if tld.nil?
      return domain.scan(/[a-z0-9]+\.[a-z]+$/).first if tld.length>3
      return domain.scan(/[a-z]+\.[a-z]+\.[a-z]+$/).first
   end

      

   
   def self.find_handler(domain)
      handler=nil
      sld=domain.scan(/\.[a-z]+\.[a-z]+$/).first
      tld=domain.scan(/\.[a-z]+$/).first
	   handler=@@handlers[sld]
      handler=@@handlers[tld] if handler.nil?
	   return handler
   end



   

   def self.perform_search(domain)
      record=Hash.new
      handler=find_handler(domain)
      handler=method(:generic_handler) if handler.nil?
      raw_data=self.run_command_with_timeout("#{WHOIS_BIN} #{domain}")
      record["raw_data"] = raw_data
      record["domain"]=domain
      handler.call record 
      return record
   end




   # stolen without attributation ;)

   def self.run_command_with_timeout(command, timeout = 10, do_raise = false) #:nodoc:
      @output = ""
      begin
         status = Timeout::timeout(10) do
            IO.popen(command, "r") do |io|
               @output << "#{io.read.to_s}"
            end
         end
      rescue Exception => e
         if do_raise
            raise "Running command \"#{command}\" timed out."
         end
      end
      @output.strip!
      @output
   end

  



end

