# Upstream's strands-agents-sops CLI used purely as a build-time generator:
# the exported artifact is just the five SOPs rendered as Agent Skills
# (<name>/SKILL.md), ready to be merged into an opencode skills directory.
{
  lib,
  runCommand,
  python3Packages,
  fetchFromGitHub,
}:

let
  version = "1.1.3";
  src = fetchFromGitHub {
    tag = "v${version}";
    repo = "agent-sop";
    owner = "strands-agents";
    hash = "sha256-843c6dwc4Mct1T46LIBIx2ZxZnnoMA0Wprnwi4UHqew=";
  };

  strands-agents-sops = python3Packages.buildPythonApplication {
    inherit version src;
    pname = "strands-agents-sops";
    pyproject = true;

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
  };
in
runCommand "strands-agents-sops-skills-${version}" { } ''
  mkdir $out
  ${lib.getExe strands-agents-sops} skills --output-dir $out
''
