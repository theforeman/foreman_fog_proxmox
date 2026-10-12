import { useState, useEffect } from 'react';
import { API } from 'foremanReact/redux/API';

const useVolumes = (
  computeResourceId,
  nodeId,
  storageValue,
  contentType = null
) => {
  const [result, setResult] = useState(null);
  const requestKey = JSON.stringify([
    computeResourceId,
    nodeId,
    storageValue,
    contentType,
  ]);
  const enabled = !!(computeResourceId && nodeId && storageValue);

  useEffect(() => {
    if (!enabled) {
      setResult(null);
      return undefined;
    }

    let mounted = true;
    setResult(null);

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

        setResult({ requestKey, volumes: filtered, error: false });
      } catch (e) {
        if (mounted) {
          setResult({ requestKey, volumes: [], error: true });
        }
      }
    };

    fetchVolumes();

    return () => {
      mounted = false;
    };
  }, [
    computeResourceId,
    nodeId,
    storageValue,
    contentType,
    requestKey,
    enabled,
  ]);

  const current = enabled && result?.requestKey === requestKey ? result : null;
  return {
    volumes: current?.volumes || [],
    loadingVolumes: enabled && !current,
    volumeError: current?.error || false,
  };
};

export default useVolumes;
