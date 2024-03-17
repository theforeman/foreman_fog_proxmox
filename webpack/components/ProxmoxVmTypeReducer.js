import {
  SET_VM_TYPE,
  SET_VM_ID,
  SET_NODE,
  SET_IMAGE,
  SET_POOL,
} from './ProxmoxVmTypeActions.js';

const initialState = {
  vmType: 'qemu',
  vmId: '',
  node: '',
  image: '',
  pool: '',
};

const proxmoxVmType = (state = initialState, action) => {
  const { payload } = action;
  switch (action.type) {
    case SET_VM_TYPE:
      return {
        ...state,
        vmType: action.vmType,
      };
    case SET_VM_ID:
      return {
        ...state,
        vmId: action.vmId,
      };
    case SET_NODE:
      return {
        ...state,
        node: action.node,
      };
    case SET_IMAGE:
      return {
        ...state,
        image: action.image,
      };
    case SET_POOL:
      return {
        ...state,
        pool: action.pool,
      };
    default:
      return state;
  }
};


export default proxmoxVmType;

