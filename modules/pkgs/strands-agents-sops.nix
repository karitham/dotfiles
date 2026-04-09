{
  lib,
  python3Packages,
  fetchFromGitHub,
}:

python3Packages.buildPythonApplication rec {
  pname = "strands-agents-sops";
  version = "1.1.1";
  pyproject = true;

  src = fetchFromGitHub {
    tag = "v${version}";
    repo = "agent-sop";
    owner = "strands-agents";
    hash = "sha256-7OtPiR5v++oGU9r7ojnFTgIR67Zz+K7IGk1bQw7GyDo=";
  };

  sourceRoot = "source/python";

  nativeBuildInputs = [ python3Packages.hatchling ];

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail 'dynamic = ["version"]' 'version = "${version}"' \
      --replace-fail '"hatchling", "hatch-vcs"' '"hatchling"'
  '';

  dependencies = [ python3Packages.mcp ];

  meta = {
    description = "Natural language workflows (SOPs) for AI agents";
    license = lib.licenses.asl20;
    mainProgram = "strands-agents-sops";
  };
}
