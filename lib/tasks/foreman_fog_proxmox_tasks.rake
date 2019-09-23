# frozen_string_literal: true

require 'rake/testtask'

# Tests
namespace :test do
  desc 'Test ForemanFogProxmox'
  Rake::TestTask.new(:foreman_fog_proxmox) do |t|
    test_dir = File.join(File.dirname(__FILE__), '../..', 'test')
    t.libs << ['test', test_dir]
    t.pattern = "#{test_dir}/**/*_test.rb"
    t.verbose = true
    t.warning = false
  end
end

namespace :foreman_fog_proxmox do
  task :rubocop do
    begin
      require 'rubocop/rake_task'
      RuboCop::RakeTask.new(:rubocop_foreman_fog_proxmox) do |task|
        task.patterns = ["#{ForemanFogProxmox::Engine.root}/app/**/*.rb",
                         "#{ForemanFogProxmox::Engine.root}/lib/**/*.rb",
                         "#{ForemanFogProxmox::Engine.root}/test/**/*.rb"]
      end
    rescue StandardError
      puts 'Rubocop not loaded.'
    end

    Rake::Task['rubocop_foreman_fog_proxmox'].invoke
  end
end

Rake::Task[:test].enhance ['test:foreman_fog_proxmox']

load 'tasks/jenkins.rake'
if Rake::Task.task_defined?(:'jenkins:unit')
  Rake::Task['jenkins:unit'].enhance ['test:foreman_fog_proxmox', 'foreman_fog_proxmox:rubocop']
end
