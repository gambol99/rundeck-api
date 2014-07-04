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

def generate_parsers project
  
  @parsers[:jobs] = {}
  project.jobs do |job|  
    @parsers[:jobs][job.name] = OptionParser::new do |o|  
      o.banner = ''
      o.separator "\tjob: #{job.name}     : #{job.description}"
      o.separator ''
      job.options.each do |option|
        option_name      = option['name']
        description      = ( option['description'] || [] ).first || "no description for this option"
        if description 

        end
        if option['values'] or option['value']
          description << " ( "
          description << "defaults: '#{option['value'].blue}' " if option['value']
          description << "options: '#{option['values'].blue}' " if option['values']
          description << ")"
        end
        o.on( "--#{option_name} #{option_name.upcase}", description ) { |x| @options[:args][option_name.to_sym] = x   }
      end
      o.separator ''
    end
  end

  @parsers[:main] = OptionScrapper::new do |o|
    o.banner = "Usage: #{__FILE__} command [options]"
    o.on( '-l', '--list', 'list all the jobs within the project ') do 
      puts <<-EOF

    Project: #{project.name} : a list of jobs under this project 
    =====================================================
    Usage: #{__FILE__} run -n|--name [name] -- [options][--help|-h]

EOF
      project.jobs { |job|
        puts "%32s :    %s" % [ job.name, job.description ]
      }
      puts 
      exit 0
    end
    o.command :run, 'run / execute a job within the project' do 
      o.on( '-n NAME', '--name NAME', 'perform an execution of the job' ) do |job|
        raise ArgumentError, "the job: #{job} does not exist, please check spelling" unless project.list_jobs.include? job
        @options[:job] = job
        @jobs_options  = ( ARGV.index('--') ) ? ARGV[ARGV.index('--')+1..-1] : ARGV[ARGV.index(job)+1..-1]
        @parsers[:jobs][job].parse! @jobs_options
      end
      o.on( '-t', '--tail', 'tail the output of the execution and print to screen' ) { |x| @options[:tail] = true  }
    end
  end
end

@parsers  = {
  :jobs  => nil,
  :main  => nil
}
@options = {
  :rundeck   => 'https://rundeck.domain.com',
  :api_token => 'some_project_name',
  :project   => 'orchestration',
  :args      => {}
}
begin
  deck    = Rundeck::API.new @options
  project = deck.project @options[:project]
  # step: generate the parsers
  generate_parsers project
  # step: parse the command line options
  @parsers[:main].parse!
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
  verbose "step: tailing the execution output"
  execution.tail do |output|
    puts "%s" % [ output.chomp.light_blue ]
  end
  verbose "step: the job has finished, exit status: " << execution.status
  verbose "step: retrieve the execution output:"
  time_took = ( Time.now - start_time )
  verbose "step: time_took: %fms" % [ time_took ] 
  verbose "step: complete"
rescue OptionParser::InvalidOption => e 
  puts e.message
rescue Interrupt => e 
  verbose "exiting tho the job: #{@options[:job]} might still be running"
rescue ArgumentError => e 
  puts "[error] #{e.message}".red
  exit 1
end
