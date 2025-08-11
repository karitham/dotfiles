_: {
  programs.zellij = {
    enable = true;
    settings = {
      scroll_buffer_size = 5000;
      default_shell = "nu";
      post_command_discovery_hook = ''
        direnv exec . -- ($env.RESURRECT_COMMAND)
      '';
      default_layout = "compact";
      # default_mode = "locked";
    };
  };
}
