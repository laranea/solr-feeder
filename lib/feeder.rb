#!/bin/ruby

require 'rubygems'
require 'optparse'
require 'ostruct'
require 'rsolr'

# see http://www.ruby-forum.com/topic/54096
class Object
  def instance_exec(*args, &block)
    mname = "__instance_exec_#{Thread.current.object_id.abs}"
    class << self; self end.class_eval{ define_method(mname, &block) }
    begin
      ret = send(mname, *args)
    ensure
      class << self; self end.class_eval{ undef_method(mname) } rescue
      nil
    end
    ret
  end
end

class Feeder
  def initialize(arguments)
    
    @options = OpenStruct.new

    OptionParser.new do |opts|
      opts.banner = "Usage: feeder.rb [options]"
      opts.separator ""

      # folder
      opts.on("-d", "--dir DIR", "Input folder") do |folder|
        @options.folder = folder
      end

      # max
      opts.on("-x", "--max NUM", Integer, "Max files to process from folder") do |max|
        @options.max = max
      end

      # commit
      opts.on("-c", "--commit NUM", Integer, "Commit interval") do |commit|
        @options.commit = commit
      end

      # host
      @options.host = "localhost"
      opts.on("-h", "--host HOST", "Solr host") do |host|
        @options.host = host
      end

      # port
      @options.port = 8983
      opts.on("-p", "--port PORT", Integer, "Solr port") do |port|
        @options.port = port
      end

      # core
      opts.on("-i", "--core CORE", "Solr core") do |core|
        @options.core = core
      end

      opts.parse!(arguments)
    end

    if (@options.folder.nil?)
      puts "Missing required argument --dir."
      exit
    end

    if (@options.core.nil?)
      puts "Missing required argument --core."
      exit
    end

  end

  def feed(&block)
    url = "http://#{@options.host}:#{@options.port}/solr/#{@options.core}"
    puts "Connecting to #{url}"
    @solr = RSolr.connect :url=> url
    @fields = {}

    n = 0
    total = 0
    Dir.foreach(@options.folder) do |filename|
      next if filename == '.' or filename == '..'

      filepath = "#{@options.folder}/#{filename}"
      instance_exec(filepath, &block) if block.is_a? Proc

      response = send_to_solr
      status = response['responseHeader']['status']
      if status == 0
        puts "Adding #{filename}"
      else
        puts "ERROR: status #{status} for #{filename}"
      end

      total += 1
      n += 1
      if not @options.commit.nil? and n == @options.commit
        puts "Committing"
        @solr.commit
        n = 0
      end

      break if not @options.max.nil? and total == @options.max
    end

    if n > 0
      @solr.commit
    end
    
    puts "#{total} documents sent. Feeder complete"
  end

  def add(field, value)
    @fields[field] = value
  end

  def send_to_solr
    params = {}
    # TODO add a command-line options to pass url parameters
    message = @solr.message
    @solr.update(message.add(@fields), params)
  end
end
