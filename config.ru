require 'rubygems'
require 'bundler'
Bundler.require(:default)
$LOAD_PATH.unshift('./lib') unless $LOAD_PATH.include?('./lib')
require './lib/simple_api_tester'

run SimpleApiTester
