require 'rake/testtask'

# Tasks
namespace :foreman_proxmox do
  namespace :example do
    desc 'Example Task'
    task task: :environment do
      # Task goes here
    end
  end
end

# Tests
namespace :test do
  desc 'Test ForemanProxmox'
  Rake::TestTask.new(:foreman_proxmox) do |t|
    test_dir = File.join(File.dirname(__FILE__), '../..', 'test')
    t.libs << ['test', test_dir]
    t.pattern = "#{test_dir}/**/*_test.rb"
    t.verbose = true
    t.warning = false
  end
end

namespace :foreman_proxmox do
  task :rubocop do
    begin
      require 'rubocop/rake_task'
      RuboCop::RakeTask.new(:rubocop_foreman_proxmox) do |task|
        task.patterns = ["#{ForemanProxmox::Engine.root}/app/**/*.rb",
                         "#{ForemanProxmox::Engine.root}/lib/**/*.rb",
                         "#{ForemanProxmox::Engine.root}/test/**/*.rb"]
      end
    rescue StandardError
      puts 'Rubocop not loaded.'
    end

    Rake::Task['rubocop_foreman_proxmox'].invoke
  end
end

Rake::Task[:test].enhance ['test:foreman_proxmox']

load 'tasks/jenkins.rake'
if Rake::Task.task_defined?(:'jenkins:unit')
  Rake::Task['jenkins:unit'].enhance ['test:foreman_proxmox', 'foreman_proxmox:rubocop']
end
