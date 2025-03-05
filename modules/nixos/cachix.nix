{
  pkgs,
  lib,
  ...
}: {
  nix.settings = {
    substituters = lib.mkAfter ["https://karitham.cachix.org"];

    trusted-public-keys = lib.mkAfter ["karitham.cachix.org-1:Q0wdHZsCssuepIrtx83gHibE0LTDYLVNnvaV3Nms9U0="];
  };

  environment.systemPackages = [pkgs.cachix];
}
