require 'optparse'
require 'ostruct'

module SolrFeeder
  
  class Options
    
    def self.parse(arguments)

      @options = OpenStruct.new

      OptionParser.new do |opts|
        opts.banner = "Usage: feeder.rb [options]"
        opts.separator ""

        # dir
        opts.on("-d", "--dir DIR", "Input directory (Mandatory)") do |folder|
          @options.folder = folder
        end

        # core
        opts.on("-c", "--core CORE", "Solr core (Mandatory)") do |core|
          @options.core = core
        end

        # host
        @options.host = "localhost"
        opts.on("-o", "--host HOST", "Solr host (default 'localhost')") do |host|
          @options.host = host
        end

        # port
        @options.port = 8983
        opts.on("-p", "--port PORT", Integer, "Solr port (default '8983')") do |port|
          @options.port = port
        end

        # recursive
        @options.recursive = false
        opts.on("-r", "--recursive", "Process files in sub directories (default off)") do
          @options.recursive = true
        end

        # max
        opts.on("-x", "--max NUM", Integer, "Max files to process from input directory (Optional)") do |max|
          @options.max = max
        end

        # commit
        opts.on("-m", "--commit NUM", Integer, "Commit interval (Optional)") do |commit|
          @options.commit = commit
        end

        # archives
        @options.archives = false
        opts.on("-a", "--archives", "Process files in tar.gz and tgz archives (default off)") do
          @options.archives = true
        end

        # help
        opts.on("-h", "--help",  "Show  this  message") do
          puts opts
          exit
        end

        begin
          arguments = ["-h"] if arguments.empty?
          opts.parse!(arguments)
        rescue  OptionParser::ParseError  =>  e
          error(e.message, opts)
        end

        if (@options.folder.nil?)
          error("missing required argument: --dir", opts)
        end

        if (@options.core.nil?)
          error("missing required argument: --core", opts)
        end
      end
      @options
    end

    private
    def self.error(message, opts)
      STDERR.puts message, "\n", opts
      exit(-1)
    end
    
  end
end
