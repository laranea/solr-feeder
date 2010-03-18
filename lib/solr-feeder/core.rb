require 'solr-feeder/options'
require 'rsolr'
require 'find'

module SolrFeeder

  def self.from_args(arguments)
    Core.new(arguments)
  end

  class Core
    def initialize(arguments)
      @options = SolrFeeder::Options.parse(arguments)
    end

    def feed(&block)
      url = "http://#{@options.host}:#{@options.port}/solr/#{@options.core}"
      puts "Connecting to #{url}"
      @solr = RSolr.connect :url=> url

      n = 0
      total = 0
      Find.find(@options.folder) do |path|
        next if path == '.' or path == '..'
        if FileTest.directory?(path)
          # Don't prune initial directory
          Find.prune if path != @options.folder and not @options.recursive
          next
        end

        @fields = {}
        @params = {}
        instance_exec(path, &block) if block.is_a? Proc

        if @fields.empty?
          puts "Skipping #{path}"
          next
        end

        response = send_to_solr
        status = response['responseHeader']['status']
        if status == 0
          puts "Adding #{path}"
        else
          puts "ERROR: status #{status} for #{path}"
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
      @solr.update(@solr.message.add(@fields), @params)
    end
  end

end
