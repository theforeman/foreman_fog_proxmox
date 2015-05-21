#!/usr/bin/env ruby
require 'find'
require 'fileutils'

class String
  def camel_case
    return self if self !~ /_/ && self =~ /[A-Z]+.*/
    split('_').map(&:capitalize).join
  end
end

def usage
  puts 'This script renames the template plugin to a name of your choice'
  puts 'Please supply the desired plugin name in snake_case, e.g.'
  puts ''
  puts '    rename.rb my_awesome_plugin'
  puts ''
  exit 0
end

usage if ARGV.size != 1

snake = ARGV[0]
camel = snake.camel_case

if snake == camel
  puts "Could not camelize '#{snake}' - exiting"
  exit 1
end

old_dirs = []
Find.find('.') do |path|
  next unless File.file?(path)
  next if path =~ /\.git/
  next if path == './rename.rb'

  # Change content on all files
  system(%(sed 's/foreman_plugin_template/#{snake}/g' -i #{path} ))
  system(%(sed 's/ForemanPluginTemplate/#{camel}/g'   -i #{path} ))
end

Find.find('.') do |path|
  # Change all the paths to the new snake_case name
  if path =~ /foreman_plugin_template/i
    new = path.gsub('foreman_plugin_template', snake)
    # Recursively copy the directory and store the original for deletion
    # Check for $ because we don't need to copy template/hosts for example
    if File.directory?(path) && path =~ /foreman_plugin_template$/i
      FileUtils.cp_r(path, new)
      old_dirs << path
    else
      # gsub replaces all instances, so it will work on the new directories
      FileUtils.mv(path, new)
    end
  end
end

# Clean up
FileUtils.rm_rf(old_dirs)

FileUtils.mv('README.plugin.md', 'README.md')

puts 'All done!'
puts "Add this to Foreman's bundler configuration:"
puts ''
puts "  gem '#{snake}', :path => '#{Dir.pwd}'"
puts ''
puts 'Happy hacking!'
