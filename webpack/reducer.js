// rootReducer.js

import { combineReducers } from 'redux';
import proxmoxVmType from './components/ProxmoxVmTypeReducer';

export default combineReducers({
  proxmoxVmType,
});


