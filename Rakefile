require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|
  s.name = 'solr-feeder'
  s.version = '0.0.1'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc']
  s.summary = 'Little script to feed documents to Solr from a set of files.'
  s.description = s.summary
  s.author = 'Pascal Dimassimo'
  s.email = 'pascal@pascaldimassimo.com'
  s.files = %w(README.rdoc Rakefile) + Dir.glob("{lib}/**/*")
  s.require_path = "lib"
  s.bindir = "bin"
end

Rake::GemPackageTask.new(spec).define