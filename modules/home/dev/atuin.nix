_: {
  programs.atuin = {
    enable = true;
    flags = [
      "--disable-up-arrow"
    ];
    settings = {
      enter_accept = false;
      style = "compact";
      sync_address = "http://reg.dolly-ruffe.ts.net:8888";
    };
  };
}
