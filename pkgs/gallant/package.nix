{
  lib,
  buildGo127Module,
  fetchFromGitHub,
}:
# go.mod requires go >= 1.27.2; the default buildGoModule is still 1.26.
buildGo127Module {
  pname = "gallant";
  version = "0-unstable-2026-10-22";
  src = fetchFromGitHub {
    owner = "karitham";
    repo = "gallant";
    # config-env-defaults branch: env defaults and the resolved config.
    rev = "820b9eeccfa9a3d370d77a9d211dccbef6b2b28d";
    hash = "sha256-hZZ5n2bGesU1eymM0xbXJTPgqOdenx8tj0UZFBUB5gI=";
  };

  vendorHash = "sha256-/jAJ1jeLiRsFxfflj8sqD85rluauepXODoEeGK4l8FQ=";
  subPackages = [ "cmd/gallant" ];
  env.CGO_ENABLED = 0;
  ldflags = [
    "-s"
    "-w"
  ];

  postInstall = ''
    install -Dm644 man/gallant.1 -t $out/share/man/man1
  '';

  meta = {
    description = "Linter that checks files against prose rules with decision models";
    homepage = "https://github.com/karitham/gallant";
    mainProgram = "gallant";
    license = lib.licenses.mit;
  };
}
