import componentRegistry from 'foremanReact/components/componentRegistry';
import ProxmoxVmType from './components/ProxmoxVmType';
import './stylesheets/proxmox_server_options.css';

componentRegistry.register({
  name: 'ProxmoxVmType',
  type: ProxmoxVmType,
});
