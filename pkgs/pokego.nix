{pkgs, ...}:
pkgs.buildGoModule {
  pname = "pokego";
  version = "devel";
  src = pkgs.fetchFromGitHub {
    owner = "karitham";
    repo = "pokego";
    rev = "7b1d5d3ddb6da6a114840c96bd2e49424406add1";
    hash = "sha256-IV3yJHZcqs9j9FstabkItrrOItMo/Uy9qml+l5oW6nM=";
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
