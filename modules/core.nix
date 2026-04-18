{ lib, config, ... }:
{
  options.my.username = lib.mkOption {
    type = lib.types.str;
    description = "The username for the current user.";
  };

  config = lib.mkMerge [
    { my.username = lib.mkDefault "kar"; }
    (lib.mkIf (config.my.username != "root") {
      users.users.${config.my.username} = {
        home = "/home/${config.my.username}";
        initialPassword = "";
        isNormalUser = true;
        extraGroups = [
          "networkmanager"
          "docker"
          "wheel"
        ];
      };
    })
  ];
}
