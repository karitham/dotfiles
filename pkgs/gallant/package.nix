{
  lib,
  buildGo127Module,
  fetchFromGitHub,
}:
# go.mod requires go >= 1.27.2; the default buildGoModule is still 1.26.
buildGo127Module {
  pname = "gallant";
  version = "0-unstable-2026-10-28";
  src = fetchFromGitHub {
    owner = "karitham";
    repo = "gallant";
    # main: environment defaults, the Liquid AI d1 provider, and the exit
    # status change are all merged upstream.
    rev = "720a0a6bd726cfb7158362e68465ec0505dd4c2b";
    hash = "sha256-mbitUBMQz4trcWcyMOIVg1ixXbPBxKDk0SeV5AXxUzI=";
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
