const selectProxmoxVm = (state) => state.foremanFogProxmox.proxmoxVmType;

export const selectVmType = (state) => selectProxmoxVm(state).vmType;
export const selectVmId = (state) => selectProxmoxVm(state).vmId;
export const selectNode = (state) => selectProxmoxVm(state).node;
export const selectImage = (state) => selectProxmoxVm(state).image;
export const selectPool = (state) => selectProxmoxVm(state).pool;

