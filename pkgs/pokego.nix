{pkgs, ...}:
pkgs.buildGoModule {
  pname = "pokego";
  version = "0.3.0";
  src = pkgs.fetchgit {
    url = "https://git.jolheiser.com/pokego.git";
    hash = "sha256-NlLFuW6pOr9xt+W7nPZUTflVwrOJgkJZWlk9RJxDVO4=";
  };

  vendorHash = null;

  meta = with pkgs.lib; {
    description = "Command-line tool that lets you display Pokémon sprites in color directly in your terminal.";
    homepage = "https://git.jolheiser.com/pokego";
    license = licenses.gpl3;
    maintainers = with maintainers; [karitham];
  };
}
