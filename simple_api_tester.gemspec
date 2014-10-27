# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'simple_api_tester/version'

Gem::Specification.new do |spec|
  spec.name          = "simple_api_tester"
  spec.version       = SimpleApiTester::VERSION
  spec.authors       = ["afa"]
  spec.email         = ["afa@afanote"]
  spec.summary       = %q{tester api}
  spec.description   = %q{tester api}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_dependency 'sinatra'
  spec.add_dependency 'thin'
  spec.add_dependency 'sequel'
  spec.add_dependency 'pg'
  spec.add_development_dependency "capistrano"
end
