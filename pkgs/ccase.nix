{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "ccase";
  version = "0.4.1";

  src = fetchFromGitHub {
    owner = "rutrum";
    repo = "ccase";
    rev = "v${version}";
    hash = "sha256-/gyOFqYq324H9P30rBEKA3S1AdZKyvNsogui93rad0g=";
  };

  cargoHash = "sha256-ra/wvssSLo42oNdnXH81lwHEsfPoWFNSexFrOJb32Mw=";

  meta = {
    description = "Command line interface to convert strings into any case";
    homepage = "https://github.com/rutrum/ccase";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [karitham];
    mainProgram = "ccase";
  };
}
