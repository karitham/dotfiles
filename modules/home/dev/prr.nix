{pkgs, ...}: let
  settingsFormat = pkgs.formats.toml {};
in {
  home.packages = [pkgs.prr];
  xdg.configFile."prr/config.toml".source = settingsFormat.generate "config.toml" {
    prr = {
      token = ""; # read env
      activate_pr_metadata_experiment = true;
    };
  };
}
