File.expand_path(File.dirname(__FILE__)).tap {|pwd| $LOAD_PATH.unshift(File.join(pwd, 'lib')) unless $LOAD_PATH.include?(File.join(pwd, 'lib'))}
require 'rake'
Dir[File.join(File.dirname(__FILE__), %w(lib tasks *.rake))].each{|f| import f }
