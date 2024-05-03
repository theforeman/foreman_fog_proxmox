// actions.js

export const SET_VM_TYPE = 'SET_VM_TYPE';
export const SET_VM_ID = 'SET_VM_ID';
export const SET_NODE = 'SET_NODE';
export const SET_IMAGE = 'SET_IMAGE';
export const SET_POOL = 'SET_POOL';
export const SET_DESCRIPTION = 'SET_DESCRIPTION';

export const setVmType = (value) => ({
  type: SET_VM_TYPE,
  vmType: value,
});

export const setVmId = (value) => ({
  type: SET_VM_ID,
  vmId: value,
});

export const setNode = (value) => ({
  type: SET_NODE,
  node: value,
});

export const setImage = (value) => ({
  type: SET_IMAGE,
  image: value,
});

export const setPool = (value) => ({
  type: SET_POOL,
  pool: value,
});

export const setDescription = (value) => ({
  type: SET_DESCRIPTION,
  description: value,
});
