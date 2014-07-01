Rundeck API
===========

A simple api into rundeck - note, this was written quickly ... needs some polish so to speak :-)

    $:.unshift File.join(File.dirname(__FILE__),'.','../lib')
    require 'rundeck-cli'
    require 'optionscrapper'
    require 'pp'
    
    @options = {
      :rundeck   => 'https://rundeck.domain.com',
      :api_token => 'token_key',
      :project   => 'orchestration',
      :args      => {}
    }
    
    api = Rundeck::API.new @options
    orchestration = api.project 'orchestration'
    
    orchestration.jobs do |job|
      puts "job: #{job.name}"  
    end
    
    puts "checking for the launch job"
    launch = orchestration.job 'delete'
    puts "running the launch job"
    execution = launch.run :hostname => 'rohith333'
    puts "ran the job"
    puts "checking the execution status"
    execution.waitfor
    puts "status"
    puts execution.status



