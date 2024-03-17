import componentRegistry from 'foremanReact/components/componentRegistry';
import Demo from './components/Demo';
import ProxmoxVmType from './components/ProxmoxVmType';
import injectReducer from 'foremanReact/redux/reducers/registerReducer';
import reducer from './reducer';

injectReducer('foremanFogProxmox', reducer);

componentRegistry.register({
  name: 'Demo',
  type: Demo,
});

componentRegistry.register({
  name: 'ProxmoxVmType',
  type: ProxmoxVmType,
});
