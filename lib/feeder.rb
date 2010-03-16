#!/bin/ruby

require 'rubygems'
require 'optparse'
require 'ostruct'
require 'rsolr'

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

    n = 0
    total = 0
    Dir.foreach(@options.folder) do |filename|
      next if filename == '.' or filename == '..'

      @fields = {}
      @params = {}
    
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
    
    puts "#{total} documents sent. Feed complete"
  end

  def add_field(field, value)
    @fields[field] = value
  end

  def add_param(param, value)
    @params[param] = value
  end

  def send_to_solr
    message = @solr.message
    @solr.update(message.add(@fields), @params)
  end
end
