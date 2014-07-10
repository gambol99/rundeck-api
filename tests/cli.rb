#!/usr/bin/env ruby
#
#   Author: Rohith
#   Date: 2014-06-20 11:45:32 +0100 (Fri, 20 Jun 2014)
#
#  vim:ts=2:sw=2:et
#
$:.unshift File.join(File.dirname(__FILE__),'.','../lib')
require 'rundeck-api'
require 'optionscrapper'
require 'pp'

@options = {
  'rundeck'   => 'https://rundeck.domain.com',
  'api_token' => 'KTggyDiZvlGRHdsdlsdkowdkiwsjf',
  'project'   => 'orchestration',
  :args       => {}
}

api = Rundeck::API.new @options
orchestration = api.project 'orchestration'

orchestration.jobs do |job|
  puts "job: #{job.name}"  
end

#puts "checking for the launch job"
#launch = orchestration.job 'delete'
#puts "running the launch job"
#execution = launch.run :hostname => 'rohith333'
#puts "ran the job"
#puts "checking the execution status"
#execution.waitfor
#puts "status"
#puts execution.status


