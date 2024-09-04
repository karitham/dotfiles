{lib, ...}: {
  options.fonts = {
    mono = lib.mkOption {
      type = lib.types.str;
      default = "Hurmit Nerd Font";
      description = "Global mono font";
    };
  };
}
