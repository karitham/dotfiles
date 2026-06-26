# Single source of truth for host metadata.
# Consumed by ./default.nix (easy-hosts -> nixosConfigurations) and by
# ../flake-parts.nix (generated standalone homeConfigurations).
#
#   class "desktop" | "wsl"  -> gets a standalone home-manager config
#   class "server"           -> no home-manager
{
  kiwi = {
    arch = "x86_64";
    class = "desktop";
    tags = [ "work" ];
  };

  belaf = {
    arch = "x86_64";
    class = "desktop";
    tags = [ "secureboot" ];
  };

  ozen = {
    arch = "x86_64";
    class = "wsl";
    tags = [ ];
  };

  reg = {
    arch = "x86_64";
    class = "server";
    tags = [ ];
  };

  wakuna = {
    arch = "aarch64";
    class = "server";
    tags = [ ];
  };
}
