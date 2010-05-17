require 'solr-feeder/options'
require 'rsolr'
require 'find'
require 'tmpdir'

module Kernel

  def SolrFeeder(args, &block)
    options = SolrFeeder::Options.parse(args)
    core = SolrFeeder::Core.new(options)
    core.feed(&block)
  end
  
end

module SolrFeeder

  class Core
    def initialize(options)
      @options = options
    end

    def feed(&block)
      url = "http://#{@options.host}:#{@options.port}/solr/#{@options.core}"
      puts "Connecting to #{url}"
      @solr = RSolr.connect :url=> url

      @n = 0
      @total = 0

      recurse_folder(@options.folder, &block)

      @solr.commit if @n > 0
      puts "#{@total} documents sent. Feed complete"
    end

    def recurse_folder(folder, &block)
      Find.find(folder) do |path|
        next if path == '.' or path == '..'
        if FileTest.directory?(path)
          # Don't prune initial directory
          Find.prune if path != @options.folder and not @options.recursive
          next
        end

        if @options.archives and path =~ /\.t(ar\.)?gz$/
          process_archive(path, &block)
          next
        end

        @fields = {}
        @params = {}
        begin
          instance_exec(path, &block) if block.is_a? Proc
        rescue Exception => e
          puts "Skipping #{path} because of exception [#{e}]"
          next
        end

        if @fields.empty?
          puts "Skipping #{path}"
          next
        end

        begin
          response = send_to_solr
          status = response['responseHeader']['status']
          if status == 0
            puts "Adding #{path}"
          else
            puts "ERROR: status #{status} for #{path}"
            next
          end
        rescue Exception => e
          puts "Skipping #{path} because of exception while sending [#{e}]"
          next
        end

        @total += 1
        @n += 1
        if not @options.commit.nil? and @n == @options.commit
          puts "Committing"
          @solr.commit
          @n = 0
        end

        break if not @options.max.nil? and @total == @options.max
      end
    end

    def process_archive(path, &block)
      puts "Extracting #{path}"

      tmp_dir = File.join(Dir.tmpdir, "#{File.basename(path)}-#{$$}")
      FileUtils.rm_rf tmp_dir if File.directory?(tmp_dir)
      Dir.mkdir(tmp_dir)

      if system("tar xzf '#{path}' -C '#{tmp_dir}'")
        recurse_folder(tmp_dir, &block)
      else
        puts "ERROR extracting #{path}"
      end

      FileUtils.rm_rf tmp_dir
    end

    def add_field(field, value)
      @fields[field] = [] unless @fields[field]
      @fields[field] << value
    end

    def add_param(param, value)
      @params[param] = value
    end

    def send_to_solr
      @solr.update(@solr.message.add(@fields), @params)
    end
  end

end
