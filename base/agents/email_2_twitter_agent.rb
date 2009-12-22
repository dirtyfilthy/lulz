require 'lib/google_contacts'
module Lulz
	class  Email2TwitterAgent < Agent
      searcher
      set_description "resolve an email address to a twitter account"
      one_at_a_time
		def self.accepts?(pred)
         return false if Resources.get_gmail_account.nil? and Resources.get_twitter_account.nil?
      
			return (pred.object.is_a?(EmailAddress) and not is_processed?(pred.object))
			return false unless exclusive
		end

		default_process :parse
      def parse(pred)
			email=pred.object	
         emails=self._world.objects.select { |e| e.is_a?(EmailAddress) and not is_processed?(e) and not e.blank? }
			emails.slice!(0,5)
			emails=emails << email
			emails.uniq!

			return if emails.empty?
	r_emails=emails.clone
	emails.each { |e| set_processed(e) }
         twitters={}
         gmail=Resources.get_gmail_account
			contacts=GoogleContacts.new(gmail.username,gmail.password)
         contacts.delete_all
         sleep 2
	emails.each { |e| contacts.add(e) }
	 contacts.refresh
	 agent=Agent.get_web_agent
         twitter=Resources.get_twitter_account
			page=agent.get("http://twitter.com/login")
         form=page.forms[1]
         form["session[username_or_email]"]=twitter.username
         form["session[password]"]=twitter.password
         page=form.click_button
	 page=agent.get('http://twitter.com/invitations?service=gmail')
         form=page.forms[1]
         form['emailaddress']="#{gmail.username}@gmail.com"
         form['password']=gmail.password
         page=form.click_button
         refresh_page=page.root.to_html.scan(/<meta http-equiv="refresh" content="\d+;url=(.*?)"/).first.first rescue nil
	 sleep 10
         page=agent.get(refresh_page)
	 if page.root.to_html =~ /None of your contacts are on Twitter/
		 return
         end
         page.root.css("#contacts-table .name").each do |twit|
            html=twit.to_html
            username=html.scan(/<strong>(.*?)<\/strong>/).first.first.downcase

            email=html.scan(/<span style="color: #666;">\&lt;(.*?)\&gt;<\/span>/).first.first
            email.gsub!(/\.\.\.$/,"")
            real_email=""
	    emails.each do |em|
	    	next if em.blank?   
               	if em.to_s.include?(email)
                  twitters[em]=username
		  break  
               	end
            end
         end
         twitters.each do |email,username|
            url=URI.parse("http://twitter.com/#{username}/")
            brute_fact url, :is_twitter_url, true
            brute_fact email, :email_search_result_url, url
         end
      end

   end

end
