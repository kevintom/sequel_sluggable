require 'rake'

# Load this library's version information
require File.expand_path('../lib/version', __FILE__)

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.version = Sequel::Plugins::Sluggable::VERSION
    gem.name = "sequel_sluggable"
    gem.summary = "Sequel plugin which provides Slug functionality for model."
    gem.description = gem.summary
    gem.email = "pavel.kunc@gmail.com"
    gem.homepage = "http://github.com/pk/sequel_sluggable"
    gem.authors = ["Pavel Kunc"]
    gem.add_dependency "sequel"
    gem.add_development_dependency "sqlite3-ruby"
    gem.add_development_dependency "rspec"
    gem.add_development_dependency "yard"
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  task :yardoc do
    abort "YARD is not available. In order to run yardoc, you must: sudo gem install yard"
  end
end
