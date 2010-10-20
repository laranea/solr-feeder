require 'rake/gempackagetask'

version = '0.0.6'

spec = Gem::Specification.new do |s|
  s.name = 'solr-feeder'
  s.version = version
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc']
  s.summary = 'Little script to feed documents to Solr from a set of files.'
  s.description = s.summary
  s.author = 'Pascal Dimassimo'
  s.email = 'pascal@pascaldimassimo.com'
  s.files = %w(README.rdoc Rakefile) + Dir.glob("{lib}/**/*")
  s.require_path = "lib"
  s.bindir = "bin"
  s.add_dependency('rsolr', '~> 0.12.0')
end

Rake::GemPackageTask.new(spec).define

desc "Install as a gem."
task :install => [:package] do
  sh %{gem install --no-ri pkg/solr-feeder-#{version}}
end
