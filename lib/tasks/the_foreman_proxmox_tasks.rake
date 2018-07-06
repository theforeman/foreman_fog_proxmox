require 'rake/testtask'

# Tasks
namespace :the_foreman_proxmox do
  namespace :example do
    desc 'Example Task'
    task task: :environment do
      # Task goes here
    end
  end
end

# Tests
namespace :test do
  desc 'Test TheForemanProxmox'
  Rake::TestTask.new(:the_foreman_proxmox) do |t|
    test_dir = File.join(File.dirname(__FILE__), '../..', 'test')
    t.libs << ['test', test_dir]
    t.pattern = "#{test_dir}/**/*_test.rb"
    t.verbose = true
    t.warning = false
  end
end

namespace :the_foreman_proxmox do
  task :rubocop do
    begin
      require 'rubocop/rake_task'
      RuboCop::RakeTask.new(:rubocop_the_foreman_proxmox) do |task|
        task.patterns = ["#{TheForemanProxmox::Engine.root}/app/**/*.rb",
                         "#{TheForemanProxmox::Engine.root}/lib/**/*.rb",
                         "#{TheForemanProxmox::Engine.root}/test/**/*.rb"]
      end
    rescue StandardError
      puts 'Rubocop not loaded.'
    end

    Rake::Task['rubocop_the_foreman_proxmox'].invoke
  end
end

Rake::Task[:test].enhance ['test:the_foreman_proxmox']

load 'tasks/jenkins.rake'
if Rake::Task.task_defined?(:'jenkins:unit')
  Rake::Task['jenkins:unit'].enhance ['test:the_foreman_proxmox', 'the_foreman_proxmox:rubocop']
end
