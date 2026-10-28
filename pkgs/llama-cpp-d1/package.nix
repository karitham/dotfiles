{
  llama-cpp,
  fetchFromGitHub,
  vulkanSupport ? false,
  cudaSupport ? false,
}:
# llama.cpp b11960 is the first build with the d1-2B decision model in the
# systemone endpoint. The nixpkgs package predates it, so pin the source and
# adjust the parts of the build that moved.
(llama-cpp.override { inherit vulkanSupport cudaSupport; }).overrideAttrs (old: {
  version = "11960";
  src = fetchFromGitHub {
    owner = "ggml-org";
    repo = "llama.cpp";
    tag = "b11960";
    hash = "sha256-WQAtD8Hos6fEtgPQId7nZiLGyP4asAMKJYEXZid1nqc=";
  };

  # The nixpkgs patch set targets b8401 and does not apply to b11960.
  patches = [ ];
  postPatch = "";

  # The web UI moved from tools/server/webui to tools/ui.
  npmRoot = "tools/ui";
  npmDepsHash = "sha256-XLtEZsSFdk+2SyfXzBp8HQ2e27PQPpDCn1YjePU1/9w=";

  # The suite downloads a model, which the sandbox has no network for.
  doCheck = false;
})
