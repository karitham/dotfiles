_: {
  programs.atuin = {
    enable = true;
    flags = [
      "--disable-up-arrow"
    ];
    settings = {
      enter_accept = false;
      style = "compact";
    };
  };
}
