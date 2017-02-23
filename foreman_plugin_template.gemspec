require File.expand_path('../lib/foreman_plugin_template/version', __FILE__)
require 'date'

Gem::Specification.new do |s|
  s.name        = 'foreman_plugin_template'
  s.version     = ForemanPluginTemplate::VERSION
  s.date        = Time.zone.today
  s.license     = 'GPL-3.0'
  s.authors     = ['TODO: Your name']
  s.email       = ['TODO: Your email']
  s.homepage    = 'TODO'
  s.summary     = 'TODO: Summary of ForemanPluginTemplate.'
  # also update locale/gemspec.rb
  s.description = 'TODO: Description of ForemanPluginTemplate.'

  s.files = Dir['{app,config,db,lib,locale}/**/*'] + ['LICENSE', 'Rakefile', 'README.md']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'deface'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rdoc'
end
