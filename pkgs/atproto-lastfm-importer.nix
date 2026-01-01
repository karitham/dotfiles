{
  lib,
  buildNpmPackage,
  fetchgit,
  ...
}:
buildNpmPackage {
  pname = "atproto-lastfm-importer";
  version = "0.0.2";

  src = fetchgit {
    url = "https://tangled.org/ewancroft.uk/atproto-lastfm-importer";
    rev = "8999e5ad5d1141401b8f18038b2c65f5a8917228";
    hash = "sha256-2ay/AzDQcxwMg/5HG6Foc/u0ijVSYE/UBu+dL6q9cqI=";
    deepClone = false;
  };

  npmDepsHash = "sha256-TWyPPC+QUH8rXEr4GUrx+JdgYuuLjMAdGGl7DYwi3gU=";

  meta = with lib; {
    description = "Import your Last.fm listening history to the AT Protocol network using the fm.teal.alpha.feed.play lexicon";
    homepage = "https://tangled.org/ewancroft.uk/atproto-lastfm-importer";
    license = licenses.mit;
    mainProgram = "lastfm-import";
  };
}
