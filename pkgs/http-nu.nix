{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  sqlite,
}:
rustPlatform.buildRustPackage rec {
  pname = "http-nu";
  version = "0.4.6";

  src = fetchFromGitHub {
    owner = "cablehead";
    repo = "http-nu";
    rev = "v${version}";
    hash = "sha256-C2pB66PomtQuKUJAvcEIxMsdOkMQQokmxO9uajbaxOQ=";
  };

  cargoHash = "sha256-8FEkhsc6x9MqawtEgqQp4t2Eu5E6If3YPZ6Ax34jk2A=";

  nativeBuildInputs = [
    pkg-config
    rustPlatform.bindgenHook
  ];

  doCheck = false;

  buildInputs = [
    sqlite
  ];

  meta = {
    description = "The surprisingly performant, Nushell-scriptable HTTP server that fits in your back pocket";
    homepage = "https://github.com/cablehead/http-nu";
    license = lib.licenses.mit;
    mainProgram = "http-nu";
  };
}
