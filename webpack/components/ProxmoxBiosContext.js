import React, { createContext, useContext, useMemo, useState } from 'react';
import PropTypes from 'prop-types';

const ProxmoxBiosContext = createContext(null);

export function ProxmoxBiosProvider({
  children,
  initialBios = null,
  initialEfiDiskSelected = false,
}) {
  const [bios, setBios] = useState(initialBios);
  const [efiDiskSelected, setEfiDiskSelected] = useState(
    initialEfiDiskSelected
  );

  const value = useMemo(
    () => ({ bios, setBios, efiDiskSelected, setEfiDiskSelected }),
    [bios, efiDiskSelected]
  );

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
  initialEfiDiskSelected: PropTypes.bool,
};

ProxmoxBiosProvider.defaultProps = {
  initialBios: null,
  initialEfiDiskSelected: false,
};
