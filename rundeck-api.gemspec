#!/usr/bin/ruby
#
#   Author: Rohith
#   Date: 2014-06-23 13:02:00 +0100 (Mon, 23 Jun 2014)
#
#  vim:ts=2:sw=2:et
#
$:.unshift File.join(File.dirname(__FILE__),'.','lib/rundeck-api' )
require 'version'

Gem::Specification.new do |s|
  s.name        = "rundeck-api"
  s.version     = Rundeck::Version::VERSION
  s.platform    = Gem::Platform::RUBY
  s.date        = '2014-06-23'
  s.authors     = ["Rohith Jayawardene"]
  s.email       = 'gambol99@gmail.com'
  s.homepage    = 'http://rubygems.org/gems/rundeck-api'
  s.summary     = %q{A Rundeck API - used for accessing jobs, projects, executions etc}
  s.description = %q{Uses the Rundeck rest api to access and manipulate}
  s.license     = 'MIT'
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
end
