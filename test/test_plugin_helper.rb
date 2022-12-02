# frozen_string_literal: true

# This calls the main test_helper in Foreman-core

if ENV['COVERAGE']
  require 'simplecov'

  SimpleCov.start do
    SimpleCov.root('../foreman_fog_proxmox')
    load_profile "test_frameworks"
    add_group 'Controllers', 'app/controllers'
    add_group 'Models', 'app/models'
    add_group 'Helpers', 'app/helpers'
    add_group 'Overrides', 'app/overrides'
    add_group 'Services', 'app/services'
    add_group 'Lib', 'lib'
  end
end

require 'test_helper'

# Add plugin to FactoryBot's paths
FactoryBot.definition_file_paths << File.join(File.dirname(__FILE__), 'factories')
FactoryBot.reload
