#!/usr/bin/env ruby
#
#   Author: Rohith
#   Date: 2014-06-20 11:45:32 +0100 (Fri, 20 Jun 2014)
#
#  vim:ts=2:sw=2:et
#
$:.unshift File.join(File.dirname(__FILE__),'.','../lib')
require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'rundeck-api'
require 'optionscrapper'
require 'colorize'
require 'pp'

def verbose message 
  now = Time.now.strftime('%H:%M:%S')
  puts "[#{now}] ".green << "#{message}".white if message
end

@options = {
  :rundeck   => 'https://rundeck.domain.com',
  :api_token => 'token',
  :project   => 'orchestration',
  :args      => {}
}

deck    = Rundeck::API.new @options
project = deck.project @options[:project]
Parser  = OptionScrapper::new do |o|
  o.banner = "Usage: #{__FILE__} -p|--project PROJECT command [options]"
  o.on( '-H URL',     '--rundeck URL',      'the full url of the rundeck instance' )      { |x| @options[:rundeck]   = x }
  o.on( '-t TOKEN',   '--token TOKEN',      'the api token to use when calling rundeck' ) { |x| @options[:api_token] = x }
  o.on( '-p PROJECT', '--project PROJECT',  'the name of the project within rundeck' )    { |x| @option[:project]    = x }
  project.jobs do |job|    
    o.command job.name.to_sym, job.description do 
      job.options.each do |option|
        option_name = option['name']
        description = option['description'].first
        description << " ( defaults: #{option['value']} )" if option['value']
        o.on( "--#{option_name} #{option_name.upcase}", description ) { |x| @options[:args][option_name.to_sym] = x   }
      end
      o.on_command { @options[:job] = job.name }
    end
  end
end

begin
  # step: parse the command line options
  Parser.parse!
  # step: we need to validate the job options are correct
  job   = project.job @options[:job]
  # step: extract the options
  verbose "step: validating the job options for job: #{job.name}"
  job.options.each do |option|
    option_name = option['name']
    # check: if the option does not have a default - we need to make sure a value has been given
    if option['required'] == 'true' and !option['value']
      raise ArgumentError, "you have not specified the #{option_name} option" if !@options[:args][option_name.to_sym]
    end
    # check: if the option has a regex, lets validate it
    if option['regex'] and !@options[:args][option_name.to_sym] =~ /#{option['regex']}/
      raise ArgumentError, "the option: #{option_name} is invalid, does not match regex: #{option['regex']}"
    end
  end
  start_time = Time.now
  # step: call the job the specified arguments
  verbose "step: executing job: #{@options[:job]}, project: #{@options[:projects]}"
  execution = job.run @options[:args]
  verbose "step: execution started, id: #{execution.id}, href: #{execution.href}"
  verbose "step: waiting for the job execution to finish"
  interval = 1
  execution.waitfor interval do 
    verbose "step: execution id: #{execution.id}, status: #{execution.status}, interval: #{interval}" 
  end
  verbose "step: the job has finished, exit status: " << execution.status
  verbose "step: retrieve the execution output:"
  puts execution.output.light_blue
  time_took = ( Time.now - start_time )
  verbose "step: time_took: %fms" % [ time_took ] 
  verbose "step: complete"

rescue ArgumentError => e 
  puts "[error] #{e.message}".red
  exit 1
end
