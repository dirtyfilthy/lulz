module Lulz
  class SteamProfileParserAgent < Agent

    default_process :process
    parser
    set_description "parse steam community user profiles"

    def self.accepts?(pred)
      object = pred.subject
      return (object.is_a?(URI::HTTP) && object._query_object(:first, :predicate => :is_steam_url) && !is_processed?(object))
    end

    def process(pred)
      url = pred.subject
      web = Agent.get_web_agent
      page = web.get(url)
      html = page.root.to_html

      steam_profile = SteamProfile.new
      steam_profile.url = url
      steam_profile.html_page = html
      brute_fact steam_profile, :profile_url, url

      # todo: get alias history from /id/<name>/namehistory

      # extract real name
      real_name = nil
      page.root.css("div[class='header_real_name ellipsis']").each do |element|
        unless element.css('bdi').text.to_s.strip.eql?('')
          real_name = element.css('bdi').text.to_s.strip
        end
      end

      # extract persona
      persona = nil
      page.root.css("div[class='persona_name']").each do |element|
        persona = element.css("span[class='actual_persona_name']").text.to_s.strip
      end

      # extract steam ID from JavaScript g_rgProfileData JSON
      steam_id = nil
      page.root.css("script").each do |script|
        if script.text =~ /g_rgProfileData = \{.*"steamid":"([0-9]+)"/
          steam_id = $1
        end
      end

      brute_fact  steam_profile, :nickname, Alias.new(persona) unless persona.nil?
      single_fact steam_profile, :steam_id, steam_id unless steam_id.nil?
      single_fact steam_profile, :name, Name.new(real_name) unless real_name.nil?

      set_processed url
      return
    end
  end
end

