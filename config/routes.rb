Rails.application.routes.draw do
  get 'new_action', to: 'foreman_proxmox/hosts#new_action'
end
