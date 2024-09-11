{pkgs, ...}:
pkgs.rustPlatform.buildRustPackage rec {
  pname = "nu_plugin_query";
  version = "0.97.1";
  src = pkgs.fetchFromGitHub {
    owner = "nushell";
    repo = "nushell";
    rev = version;
    sha256 = "sha256-hrcPWJ5OXFozfNux6iR/nEw/1z64N5BV4DD/JWhlH2U=";
  };
  cargoHash = "sha256-+WI6IBZLbN+d2EZUBQgfjnU3tJQVWJoYBAzGCX/hIJ8="; # Replace with the actual hash

  buildAndTestSubdir = "crates/nu_plugin_query";

  nativeBuildInputs = [pkgs.pkg-config];
  buildInputs = [pkgs.openssl];
  OPENSSL_NO_VENDOR = 1;

  meta = with pkgs.lib; {
    description = "A query plugin for Nushell";
    homepage = "https://github.com/nushell/nushell/tree/main/crates/nu_plugin_query";
    license = licenses.mit;
    maintainers = [];
  };
}
