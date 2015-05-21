Rails.application.routes.draw do
  match 'new_action', to: 'foreman_plugin_template/hosts#new_action'
end
