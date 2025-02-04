{}: _final: prev: {
  gotools = prev.gotools.overrideAttrs (old: {
    patches = [./gotools.patch];
    vendorHash = "sha256-9NSgtranuyRqtBq1oEnHCPIDFOIUJdVh5W/JufqN2Ko=";
  });
}
