{lib, ...}: {
  options.fonts = {
    mono = lib.mkOption {
      type = lib.types.str;
      default = "MartianMono Nerd Font";
      description = "Global mono font";
    };
  };
}
