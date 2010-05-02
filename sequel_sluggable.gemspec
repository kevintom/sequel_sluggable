#!/usr/bin/env gem build
# -*- encoding: utf-8 -*-

require 'date'
require 'lib/sequel_sluggable/version'

Gem::Specification.new do |gem|
  gem.name     = 'sequel_sluggable'
  gem.version  = Sequel::Plugins::Sluggable::VERSION.dup
  gem.authors  = ['Pavel Kunc']
  gem.date     = Date.today.to_s
  gem.email = 'pavel.kunc@gmail.com'
  gem.homepage = 'http://github.com/pk/sequel_sluggable'
  gem.summary = 'Sequel plugin which provides Slug functionality for model.'
  gem.description = gem.summary

  gem.has_rdoc = true 
  gem.require_paths = ['lib']
  gem.extra_rdoc_files = ['README.rdoc', 'LICENSE', 'CHANGELOG']
  gem.files = Dir['Rakefile', '{lib,spec}/**/*', 'README*', 'LICENSE*', 'CHANGELOG*'] & `git ls-files -z`.split("\0")

  gem.add_dependency 'sequel', ">= 3.0.0"
  gem.add_development_dependency 'sqlite3-ruby'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'yard'
end
