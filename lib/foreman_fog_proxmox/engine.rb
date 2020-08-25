# frozen_string_literal: true

# Copyright 2018 Tristan Robert

# This file is part of ForemanFogProxmox.

# ForemanFogProxmox is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# ForemanFogProxmox is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with ForemanFogProxmox. If not, see <http://www.gnu.org/licenses/>.

require 'deface'

module ForemanFogProxmox
  class Engine < ::Rails::Engine
    engine_name 'foreman_fog_proxmox'

    config.autoload_paths += Dir["#{config.root}/app/controllers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/helpers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/overrides"]
    config.autoload_paths += Dir["#{config.root}/app/services"]

    # Add any db migrations
    initializer 'foreman_fog_proxmox.load_app_instance_data' do |app|
      ForemanFogProxmox::Engine.paths['db/migrate'].existent.each do |path|
        app.config.paths['db/migrate'] << path
      end
    end

    initializer 'foreman_fog_proxmox.register_plugin', :before => :finisher_hook do |_app|
      Foreman::Plugin.register :foreman_fog_proxmox do
        requires_foreman '>= 1.22.0'
        # Register Proxmox VE compute resource in foreman
        compute_resource ForemanFogProxmox::Proxmox
        parameter_filter(ComputeResource, :uuid)
        # add dashboard widget
        widget 'foreman_fog_proxmox_widget', name: N_('Foreman Fog Proxmox widget'), sizex: 8, sizey: 1
        security_block :foreman_fog_proxmox do
          permission :view_compute_resource, { :foreman_fog_proxmox/compute_resources =>
          [:ostemplates_by_node_and_storage, :isos_by_node_and_storage, :ostemplates_by_node, :isos_by_node, :storages_by_node, :iso_storages_by_node, :bridges_by_node] }
        end
      end
    end

    # Precompile any JS or CSS files under app/assets/
    # If requiring files from each other, list them explicitly here to avoid precompiling the same
    # content twice.
    assets_to_precompile =
      Dir.chdir(root) do
        Dir['app/assets/javascripts/foreman_fog_proxmox/**/*', 'app/assets/stylesheets/foreman_fog_proxmox/**/*'].map do |f|
          f.split(File::SEPARATOR, 4).last
        end
      end
    initializer 'foreman_fog_proxmox.assets.precompile' do |app|
      app.config.assets.precompile += assets_to_precompile
    end
    initializer 'foreman_fog_proxmox.configure_assets', group: :assets do
      SETTINGS[:foreman_fog_proxmox] = {
        assets: {
          precompile: assets_to_precompile
        }
      }
    end

    rake_tasks do
      Rake::Task['db:seed'].enhance do
        ForemanFogProxmox::Engine.load_seed
      end
    end

    initializer 'foreman_fog_proxmox.register_gettext', after: :load_config_initializers do |_app|
      locale_dir = File.join(File.expand_path('../..', __dir__), 'locale')
      locale_domain = 'foreman_fog_proxmox'
      Foreman::Gettext::Support.add_text_domain locale_domain, locale_dir
    end

    config.to_prepare do
      require 'fog/compute/proxmox/models/server'
      require 'fog/compute/proxmox/models/server_config'
      require 'fog/compute/proxmox/models/disk'
      require 'fog/compute/proxmox/models/interface'
      require 'fog/compute/proxmox/models/volume'
      require 'fog/compute/proxmox/models/node'

      Fog::Proxmox::Compute::Server.include FogExtensions::Proxmox::Server
      Fog::Proxmox::Compute::ServerConfig.include FogExtensions::Proxmox::ServerConfig
      Fog::Proxmox::Compute::Disk.include FogExtensions::Proxmox::Disk
      Fog::Proxmox::Compute::Interface.include FogExtensions::Proxmox::Interface
      Fog::Proxmox::Compute::Volume.include FogExtensions::Proxmox::Volume
      ::ComputeResourcesController.include ForemanFogProxmox::Controller::Parameters::ComputeResource
      Fog::Proxmox::Compute::Node.include FogExtensions::Proxmox::Node
      ::Host::Managed.include Orchestration::Proxmox::Compute
      ::Host::Managed.include HostExt::Proxmox::Interfaces
    end
  end
end
