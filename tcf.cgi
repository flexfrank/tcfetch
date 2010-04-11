#!/usr/local/bin/ruby19
require_relative "tcffront"
Rack::Handler::CGI.run(TCFetchFront.new)
