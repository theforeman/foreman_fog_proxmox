Deface::Override.new(
  virtual_path: 'compute_attributes/_compute_form',
  name: 'remove_networks_and_volumes_partial',
  remove: "erb[loud]:contains('render :partial => \"compute_resources_vms/form/networks\"'), erb[loud]:contains('render :partial => \"compute_resources_vms/form/volumes\"')"
)
