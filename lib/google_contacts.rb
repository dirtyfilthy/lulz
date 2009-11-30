$:.unshift File.dirname(__FILE__)
require 'gdata'
require 'pp'
require "rexml/document"
class GoogleContacts
   def initialize(username,password)

      @g_contacts= GData::Client::Contacts.new
      @g_contacts.source = 'my_cool_application'
      @g_contacts.clientlogin(username, password)
      feed = @g_contacts.get('http://www.google.com/m8/feeds/contacts/default/full').to_xml
      @edit_urls={}
      feed.elements.each("entry") do |entry|
         @edit_urls[entry.elements["gd:email"].attributes['address']]=entry.elements["link[@rel='edit']"].attributes['href']
      end
   end 
  
   def refresh
	feed = @g_contacts.get('http://www.google.com/m8/feeds/contacts/default/full').to_xml
	@edit_urls={}
       feed.elements.each("entry") do |entry|
         @edit_urls[entry.elements["gd:email"].attributes['address']]=entry.elements["link[@rel='edit']"].attributes['href']
      end

   end

   def contacts
      @edit_urls.keys
   end

   def delete(email)
      @g_contacts.delete(@edit_urls[email]) unless @edit_urls[email]
      @edit_urls.delete(email)
   end 

   def delete_all
   
      @edit_urls.each_value do |edit_url|
        @g_contacts.delete(edit_url)
      end
      @edit_urls.clear

   end

   def add(email)
      new_contact_xml="<atom:entry xmlns:atom='http://www.w3.org/2005/Atom' xmlns:gd='http://schemas.google.com/g/2005'>" +
         "<atom:category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/contact/2008#contact' />" +
         "<atom:title type='text'>#{email.to_s}</atom:title>" +
         "<gd:email rel='http://schemas.google.com/g/2005#work' address='#{email.to_s}' />" +
         "</atom:entry>"
      feed = @g_contacts.post('http://www.google.com/m8/feeds/contacts/default/full',new_contact_xml).to_xml
      @edit_urls[feed.elements["gd:email"].attributes['address']]=feed.elements["link[@rel='edit']"].attributes['href']
   end
      


end











