{...}: {
  programs.atuin = {
    enable = true;
    enableNushellIntegration = true;
    flags = [
      "--disable-up-arrow"
    ];
    settings = {
      enter_accept = false;
      style = "compact";
    };
  };
}
