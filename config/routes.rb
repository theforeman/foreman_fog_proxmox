Rails.application.routes.draw do
  get 'new_action', to: 'foreman_plugin_template/hosts#new_action'
end
