{lib, ...}: {
  options.fonts = {
    mono = lib.mkOption {
      type = lib.types.str;
      default = "TX-02 Medium";
      description = "Global mono font";
    };
  };
}
