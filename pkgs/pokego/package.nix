{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule {
  pname = "pokego";
  version = "devel";
  src = fetchFromGitHub {
    owner = "karitham";
    repo = "pokego";
    # pinned; was rev = "main" (floating)
    rev = "4b2e7856badae1dd315d4d3bcf798b08b643ee42";
    hash = "sha256-zd5HNg63e6fdBDM+ri6NpA4gU4uEvvvs69XDOTFOQr8=";
  };

  vendorHash = "sha256-Eykg/qGqWA+qxeFPAhd0BERHtLj5X7kMQo/IPp1yRU4=";
  env.CGO_ENABLED = 0;
  flags = [ "-trimpath" ];
  ldflags = [
    "-s"
    "-w"
    "-extldflags -static"
  ];

  meta = with lib; {
    description = "Command-line tool that lets you display Pokémon sprites in color directly in your terminal.";
    homepage = "https://github.com/karitham/pokego";
    mainProgram = "pokego";
    license = licenses.gpl3;
    maintainers = with maintainers; [ karitham ];
  };
}
