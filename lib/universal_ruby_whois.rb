require 'rubygems'
require 'activesupport'
require 'net/http'
require 'uri'
require 'time'
require 'timeout'

require File.dirname(__FILE__) + '/support/string'
require File.dirname(__FILE__) + '/support/extended_regexp'
Regexp.class_eval do
  include Whois::ExtendedRegexp
end

require File.dirname(__FILE__) + '/universal_ruby_whois/domain'
require File.dirname(__FILE__) + '/universal_ruby_whois/server'
require File.dirname(__FILE__) + '/universal_ruby_whois/server_list'

module Whois

  # This is a wrapper around the main domain lookup function.  It allows you to simply call:
  #   Whois.find("somedomain.com")
  #
  # It returns a Whois::Domain object if found, or nil if an appropriate whois server can't be found.
  def find(domain)
    ::Whois::Domain.find(domain)
  end

  module_function :find #:nodoc:

end
