import React, { createContext, useContext, useMemo, useState } from "react";

const ProxmoxBiosContext = createContext(null);

export function ProxmoxBiosProvider({ children, initialBios = null }) {
  const [bios, setBios] = useState(initialBios);

  // memoize so the provider value object changes only when bios changes
  const value = useMemo(() => ({ bios, setBios }), [bios]);

  return <ProxmoxBiosContext.Provider value={value}>{children}</ProxmoxBiosContext.Provider>;
}

export function useBios() {
  const ctx = useContext(ProxmoxBiosContext);
  if (!ctx) throw new Error("useBios must be used inside <ProxmoxBiosProvider>");
  return ctx;
}
