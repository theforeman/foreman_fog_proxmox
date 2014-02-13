require 'deface'

module ForemanPluginTemplate
  class Engine < ::Rails::Engine

    config.autoload_paths += Dir["#{config.root}/app/controllers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/helpers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/overrides"]

    # Add any db migrations
    initializer "foreman_plugin_template.load_app_instance_data" do |app|
      app.config.paths['db/migrate'] += ForemanPluginTemplate::Engine.paths['db/migrate'].existent
    end

    initializer 'foreman_plugin_template.register_plugin', :after=> :finisher_hook do |app|
      Foreman::Plugin.register :foreman_plugin_template do
        requires_foreman '>= 1.4'

        # Add permissions
        security_block :foreman_plugin_template do
          permission :view_foreman_plugin_template, {:'foreman_plugin_template/hosts' => [:new_action] }
        end

        # Add a new role called 'Discovery' if it doesn't exist
        role "ForemanPluginTemplate", [:view_foreman_plugin_template]

        #add menu entry
        menu :top_menu, :template,
             :url_hash => {:controller => :'foreman_plugin_template/hosts', :action => :new_action },
             :caption  => 'ForemanPluginTemplate',
             :parent   => :hosts_menu,
             :after    => :hosts
      end
    end

    #Include concerns in this config.to_prepare block
    config.to_prepare do
      begin
        Host::Managed.send(:include, ForemanPluginTemplate::HostExtensions)
        HostsHelper.send(:include, ForemanPluginTemplate::HostsHelperExtensions)
      rescue => e
        puts "ForemanPluginTemplate: skipping engine hook (#{e.to_s})"
      end
    end

    rake_tasks do
      Rake::Task['db:seed'].enhance do
        ForemanPluginTemplate::Engine.load_seed
      end
    end

  end
end
