File.expand_path(File.dirname(__FILE__)).tap {|pwd| $LOAD_PATH.unshift(File.join(pwd, 'lib')) unless $LOAD_PATH.include?(File.join(pwd, 'lib'))}
require File.dirname(__FILE__) + '/lib/simple_api_tester'
# SimpleApiTester.run! :port => 2003
require 'thin'
Thin::Server.start 'tmp/sockets/thin.sock', SimpleApiTester

