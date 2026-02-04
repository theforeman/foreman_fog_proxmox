import { useState, useEffect } from 'react';
import { API } from 'foremanReact/redux/API';

const useVolumes = (
  computeResourceId,
  nodeId,
  storageValue,
  contentType = null
) => {
  const [volumes, setVolumes] = useState([]);
  const [loadingVolumes, setLoadingVolumes] = useState(false);
  const [volumeError, setVolumeError] = useState(false);

  useEffect(() => {
    if (!computeResourceId || !nodeId || !storageValue) {
      setVolumes([]);
      setLoadingVolumes(false);
      setVolumeError(false);
      return undefined;
    }

    let mounted = true;
    setLoadingVolumes(true);
    setVolumeError(false);
    setVolumes([]);

    const fetchVolumes = async () => {
      const url = `/foreman_fog_proxmox/volumes/${encodeURIComponent(
        computeResourceId
      )}/${encodeURIComponent(nodeId)}/${encodeURIComponent(storageValue)}`;

      try {
        const { data } = await API.get(url);
        if (!mounted) return;

        const safe = Array.isArray(data) ? data : [];
        const filtered = contentType
          ? safe.filter(v => (v?.content || '').includes(contentType))
          : safe;

        setVolumes(filtered);
        setVolumeError(false);
      } catch (e) {
        if (mounted) {
          setVolumes([]);
          setVolumeError(true);
        }
      } finally {
        if (mounted) {
          setLoadingVolumes(false);
        }
      }
    };

    fetchVolumes();

    return () => {
      mounted = false;
    };
  }, [computeResourceId, nodeId, storageValue, contentType]);

  return { volumes, loadingVolumes, volumeError };
};

export default useVolumes;
