# Copyright (C) 2008 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'gdata/client/base'
require 'gdata/client/apps'
require 'gdata/client/blogger'
require 'gdata/client/booksearch'
require 'gdata/client/calendar'
require 'gdata/client/contacts'
require 'gdata/client/doclist'
require 'gdata/client/finance'
require 'gdata/client/gbase'
require 'gdata/client/gmail'
require 'gdata/client/health'
require 'gdata/client/notebook'
require 'gdata/client/photos'
require 'gdata/client/spreadsheets'
require 'gdata/client/webmaster_tools'
require 'gdata/client/youtube'
  
module GData
  module Client
    class AuthorizationError < RuntimeError
    end
    
    class BadRequestError < RuntimeError
    end
    
    # An error caused by ClientLogin issuing a CAPTCHA error.
    class CaptchaError < RuntimeError
      # The token identifying the CAPTCHA
      attr_reader :token
      # The URL to the CAPTCHA image
      attr_reader :url
      
      def initialize(token, url)
        @token = token
        @url = url
      end
    end
    
    class ServerError < RuntimeError
    end
    
    class UnknownError < RuntimeError
    end
    
    class VersionConflictError < RuntimeError
    end  
    
  end
end