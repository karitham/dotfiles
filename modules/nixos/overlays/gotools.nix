_final: prev: {
  gotools = prev.gotools.overrideAttrs (old: {
    patches = [./gotools.patch];
    vendorHash = "sha256-+jhCNi7bGkRdI1Ywfe3q4i+zcm3UJ0kbQalsDD3WkS4=";
  });
}
