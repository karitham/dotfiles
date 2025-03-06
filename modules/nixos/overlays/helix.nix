_: prev: {
  helix = prev.helix.overrideAttrs (old: {
    patches = [
      (prev.fetchurl
        {
          url = "https://github.com/helix-editor/helix/commit/c59f72f2376bc9809cb9b2ebbf7d0dcb4141fbb8.patch";
          hash = "sha256-z7eH2Z1rBWqw1R8oySO5OZ0BnKfB9MHjUWMVHLMqDsY=";
        })
    ];

    doCheck = false;
  });
}
