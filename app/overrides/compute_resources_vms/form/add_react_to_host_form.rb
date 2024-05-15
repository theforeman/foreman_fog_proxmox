Deface::Override.new(
  :virtual_path => 'hosts/_unattended',
  :name => 'add_react_js_to_host_form',
  :replace_contents => "div#compute_resource",
  :text => "<%= render('compute_resources_vms/form/proxmox/add_react_js_to_host_form', host: @host, vm: @vm, compute_resource: @host.compute_resource) if @host.compute_resource %>",
  :original => 'ce6211df4eac241538eb3844e2ba5fb911a98772',
)

