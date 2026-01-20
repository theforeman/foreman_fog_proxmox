import React, { createContext, useContext, useMemo, useState } from 'react';
import PropTypes from 'prop-types';

const ProxmoxBiosContext = createContext(null);

export function ProxmoxBiosProvider({ children, initialBios = null }) {
  const [bios, setBios] = useState(initialBios);

  // memoize so the provider value object changes only when bios changes
  const value = useMemo(() => ({ bios, setBios }), [bios]);

  return (
    <ProxmoxBiosContext.Provider value={value}>
      {children}
    </ProxmoxBiosContext.Provider>
  );
}

export function useBios() {
  const ctx = useContext(ProxmoxBiosContext);
  if (!ctx)
    throw new Error('useBios must be used inside <ProxmoxBiosProvider>');
  return ctx;
}

ProxmoxBiosProvider.propTypes = {
  children: PropTypes.object.isRequired,
  initialBios: PropTypes.string,
};

ProxmoxBiosProvider.defaultProps = {
  initialBios: null,
};
