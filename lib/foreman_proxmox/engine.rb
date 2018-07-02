# frozen_string_literal: true

# Copyright 2018 Tristan Robert

# This file is part of ForemanProxmox.

# ForemanProxmox is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# ForemanProxmox is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with ForemanProxmox. If not, see <http://www.gnu.org/licenses/>.

module ForemanProxmox
  class Engine < ::Rails::Engine
    engine_name 'foreman_proxmox'

    config.autoload_paths += Dir["#{config.root}/app/controllers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/helpers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/overrides"]

    # Add any db migrations
    initializer 'foreman_proxmox.load_app_instance_data' do |app|
      ForemanProxmox::Engine.paths['db/migrate'].existent.each do |path|
        app.config.paths['db/migrate'] << path
      end
    end

    initializer 'foreman_proxmox.register_plugin', :before => :finisher_hook do |_app|
      Foreman::Plugin.register :foreman_proxmox do
        requires_foreman '>= 1.17'
        # Register Proxmox VE compute resource in foreman
        compute_resource ForemanProxmox::Proxmox
        parameter_filter(ComputeResource, :uuid)
        # add dashboard widget
        widget 'foreman_proxmox_widget', name: N_('Foreman plugin template widget'), sizex: 4, sizey: 1
      end
    end

    # Precompile any JS or CSS files under app/assets/
    # If requiring files from each other, list them explicitly here to avoid precompiling the same
    # content twice.
    assets_to_precompile =
      Dir.chdir(root) do
        Dir['app/assets/javascripts/**/*', 'app/assets/stylesheets/**/*'].map do |f|
          f.split(File::SEPARATOR, 4).last
        end
      end
    initializer 'foreman_proxmox.assets.precompile' do |app|
      app.config.assets.precompile += assets_to_precompile
    end
    initializer 'foreman_proxmox.configure_assets', group: :assets do
      SETTINGS[:foreman_proxmox] = { 
        assets: { 
          precompile: assets_to_precompile 
        }, :js_compressor => Uglifier.new(:mangle => false) }
    end

    rake_tasks do
      Rake::Task['db:seed'].enhance do
        ForemanProxmox::Engine.load_seed
      end
    end

    initializer 'foreman_proxmox.register_gettext', after: :load_config_initializers do |_app|
      locale_dir = File.join(File.expand_path('../..', __dir__), 'locale')
      locale_domain = 'foreman_proxmox'
      Foreman::Gettext::Support.add_text_domain locale_domain, locale_dir
    end

    config.to_prepare do
      require 'fog/compute/proxmox/models/server'
      require 'fog/compute/proxmox/models/server_config'

      Fog::Compute::Proxmox::Server.send :include, FogExtensions::Proxmox::Server
      Fog::Compute::Proxmox::ServerConfig.send :include, FogExtensions::Proxmox::ServerConfig
      ::ComputeResourcesController.send :include, ForemanProxmox::Controller::Parameters::ComputeResource
    end

  end
end
