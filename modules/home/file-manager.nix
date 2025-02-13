{pkgs, ...}: {
  programs = {
    fzf.enable = true;
    pistol.enable = true;

    xplr.enable = true;
    xplr.plugins = {
      fzf = pkgs.fetchFromGitHub {
        owner = "sayanarijit";
        repo = "fzf.xplr";
        rev = "c8991f92946a7c8177d7f82ed939d845746ebaf5";
        hash = "sha256-dpnta67p3fYEO3/GdvFlqzdyiMaJ9WbsnNmoIRHweMI=";
      };
    };
    xplr.extraConfig = ''
      require("fzf").setup{
        mode = "default",
        key = "ctrl-f",
        bin = "fzf",
        args = "--preview 'pistol {}'",
        recursive = true,  -- If true, search all files under $PWD
        enter_dir = false,  -- Enter if the result is directory
      }
    '';
  };
}
