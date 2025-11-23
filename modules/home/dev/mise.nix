{
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.programs.mise.enable {
    programs.nushell = {
      envFile.text = ''
        let mise_path = $nu.default-config-dir | path join mise.nu
        ^mise activate nu | save $mise_path --force
      '';
      configFile.text = ''
        use ($nu.default-config-dir | path join mise.nu)
      '';
    };
  };
}
