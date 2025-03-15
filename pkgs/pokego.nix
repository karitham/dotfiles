{pkgs, ...}:
pkgs.buildGoModule {
  pname = "pokego";
  version = "devel";
  src = pkgs.fetchFromGitHub {
    owner = "karitham";
    repo = "pokego";
    rev = "main";
    hash = "sha256-zd5HNg63e6fdBDM+ri6NpA4gU4uEvvvs69XDOTFOQr8=";
  };

  vendorHash = "sha256-Eykg/qGqWA+qxeFPAhd0BERHtLj5X7kMQo/IPp1yRU4=";
  env.CGO_ENABLED = 0;
  flags = ["-trimpath"];
  ldflags = [
    "-s"
    "-w"
    "-extldflags -static"
  ];

  meta = with pkgs.lib; {
    description = "Command-line tool that lets you display Pokémon sprites in color directly in your terminal.";
    homepage = "https://github.com/karitham/pokego";
    mainProgram = "pokego";
    license = licenses.gpl3;
    maintainers = with maintainers; [karitham];
  };
}
