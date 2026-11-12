# OpenCode and albedo both discover the portable Agent Skills directory,
# ~/.agents/skills, so it is linked once here for every agent.
{
  config,
  lib,
  pkgs,
  self',
  ...
}:
{
  config = lib.mkIf config.dev.agents.enable {
    home.file.".agents/skills" = {
      source = import ./agent-skills.nix { inherit pkgs self'; };
      recursive = true;
    };
  };
}
