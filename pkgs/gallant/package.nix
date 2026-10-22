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
    # exit-on-failed-check branch: exits 1 when a rule fails.
    rev = "c3bdde119b56b558d0370fd8d7f157d294b88ab4";
    hash = "sha256-ZQkCiWDKufD1PCu5gTRfzDtvGMpI4EX/OIsJKSoBXLc=";
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
