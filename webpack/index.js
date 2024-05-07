import componentRegistry from 'foremanReact/components/componentRegistry';
import Demo from './components/Demo';
import ProxmoxVmType from './components/ProxmoxVmType';


componentRegistry.register({
  name: 'Demo',
  type: Demo,
});

componentRegistry.register({
  name: 'ProxmoxVmType',
  type: ProxmoxVmType,
});
