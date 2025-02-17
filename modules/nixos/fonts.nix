{
  config,
  lib,
  pkgs,
  ...
}: {
  options.fonts = {
    mono = lib.mkOption {
      type = lib.types.str;
      default = "TX-02 Medium";
      description = "Global mono font";
    };
  };

  config = lib.mkIf config.desktop.enable {
    fonts = {
      packages = with pkgs; [
        victor-mono
        lexend
        nerd-fonts.jetbrains-mono
      ];

      fontconfig = {
        defaultFonts = {
          monospace = [
            config.fonts.mono
            "JetBrainsMono"
            "JetBrainsMono Nerd Font"
            "Noto Color Emoji"
          ];
          sansSerif = [
            "Lexend"
            "Noto Color Emoji"
          ];
          serif = [
            "Noto Serif"
            "Noto Color Emoji"
          ];
          emoji = ["Noto Color Emoji"];
        };
      };
    };
  };
}
