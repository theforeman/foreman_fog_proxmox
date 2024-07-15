import { sprintf, translate as __ } from 'foremanReact/common/I18n';

const humanSize = size => {
  const i = Math.floor(Math.log(size) / Math.log(1024));
  return `${(size / 1000 ** i).toFixed(2) * 1} ${
    ['B', 'kB', 'MB', 'GB', 'TB'][i]
  }`;
};

export const createStoragesMap = (
  storages,
  filterContent = null,
  nodeId = null
) =>
  storages
    .filter(st => {
      const contentMatch = filterContent
        ? st.content.includes(filterContent)
        : true;
      const nodeMatch = nodeId ? st.node_id === nodeId : true;
      return contentMatch && nodeMatch;
    })
    .map(st => ({
      value: st.storage,
      label: sprintf(
        __('%(name)s (free: %(free)s, used: %(used)s, total: %(total)s)'),
        {
          name: st.storage,
          free: humanSize(st.avail),
          used: humanSize(st.used),
          total: humanSize(st.total),
        }
      ),
    }));

export const imagesByStorage = (storages, nodeId, storageId, type = 'iso') => {
  const storage = storages.find(
    st => st.node_id === nodeId && st.storage === storageId
  );

  const filteredVolumes = storage.volumes
    .filter(volume => volume.content.includes(type))
    .sort((a, b) => a.volid.localeCompare(b.volid))
    .map(volume => ({
      value: volume.volid,
      label: volume.volid,
    }));

  return filteredVolumes;
};
