{pkgs, ...}:
pkgs.buildGoModule rec {
  pname = "pokego";
  version = "0.3.0";
  src = pkgs.fetchFromGitHub {
    owner = "rubiin";
    repo = "pokego";
    tag = "v${version}";
    hash = "sha256-cFpEi8wBdCzAl9dputoCwy8LeGyK3UF2vyylft7/1wY=";
  };

  vendorHash = "sha256-7SoKHH+tDJKhUQDoVwAzVZXoPuKNJEHDEyQ77BPEDQ0=";

  meta = with pkgs.lib; {
    description = "Command-line tool that lets you display Pokémon sprites in color directly in your terminal.";
    homepage = "https://github.com/rubiin/pokego";
    license = licenses.gpl3;
    maintainers = with maintainers; [karitham];
  };
}
