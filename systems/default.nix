{ self, inputs, ... }:
{
  imports = [ inputs.easy-hosts.flakeModule ];

  config.easy-hosts = {
    shared = {
      modules = [ ../modules/core.nix ];

      specialArgs = { inherit inputs self; };
    };

    additionalClasses = {
      desktop = "nixos";
      server = "nixos";
      wsl = "nixos";
    };

    perClass = class: { modules = [ ../modules/${class}/default.nix ]; };

    perTag = tag: { modules = [ ../modules/tags/${tag}.nix ]; };

    hosts = {
      kiwi = {
        class = "desktop";
        tags = [ "work" ];
      };

      ozen = {
        class = "wsl";
      };

      reg = {
        class = "server";
      };

      belaf = {
        class = "desktop";
        tags = [ "secureboot" ];
      };

      wakuna = {
        arch = "aarch64";
        class = "server";
      };
    };
  };
}
