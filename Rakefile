require 'rubygems'
# require 'bundler/setup'
# Bundler.setup
# Bundler.require(:default)
$LOAD_PATH.unshift('./lib') unless $LOAD_PATH.include?('./lib')
$LOAD_PATH.unshift('./models') unless $LOAD_PATH.include?('./models')
# require 'simple_api_tester'
# File.expand_path(File.dirname(__FILE__)).tap {|pwd| $LOAD_PATH.unshift(File.join(pwd, 'models')) unless $LOAD_PATH.include?(File.join(pwd, 'models'))}
# File.expand_path(File.dirname(__FILE__)).tap {|pwd| $LOAD_PATH.unshift(File.join(pwd, 'lib')) unless $LOAD_PATH.include?(File.join(pwd, 'lib'))}
require 'rake'
# p require 'simple_api'
# require 'sequel'
require 'init_db'
# require 'simple_api_tester'
Dir[File.join(File.dirname(__FILE__), %w(lib tasks *.rake))].each{|f| import f }
