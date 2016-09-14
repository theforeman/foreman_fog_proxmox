require 'rake/testtask'

# Tasks
namespace :foreman_plugin_template do
  namespace :example do
    desc 'Example Task'
    task task: :environment do
      # Task goes here
    end
  end
end

# Tests
namespace :test do
  desc 'Test ForemanPluginTemplate'
  Rake::TestTask.new(:foreman_plugin_template) do |t|
    test_dir = File.join(File.dirname(__FILE__), '../..', 'test')
    t.libs << ['test', test_dir]
    t.pattern = "#{test_dir}/**/*_test.rb"
    t.verbose = true
    t.warning = false
  end
end

namespace :foreman_plugin_template do
  task :rubocop do
    begin
      require 'rubocop/rake_task'
      RuboCop::RakeTask.new(:rubocop_foreman_plugin_template) do |task|
        task.patterns = ["#{ForemanPluginTemplate::Engine.root}/app/**/*.rb",
                         "#{ForemanPluginTemplate::Engine.root}/lib/**/*.rb",
                         "#{ForemanPluginTemplate::Engine.root}/test/**/*.rb"]
      end
    rescue
      puts 'Rubocop not loaded.'
    end

    Rake::Task['rubocop_foreman_plugin_template'].invoke
  end
end

Rake::Task[:test].enhance ['test:foreman_plugin_template']

load 'tasks/jenkins.rake'
if Rake::Task.task_defined?(:'jenkins:unit')
  Rake::Task['jenkins:unit'].enhance ['test:foreman_plugin_template', 'foreman_plugin_template:rubocop']
end
