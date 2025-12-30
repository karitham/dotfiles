{lib, ...}: {
  options.my.username = lib.mkOption {
    type = lib.types.str;
    description = "The username for the current user.";
    default = "kar";
  };
}
