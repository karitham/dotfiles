# OpenCode and albedo both discover the portable Agent Skills directory,
# ~/.agents/skills, so it is linked once here for every agent.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # symlinkJoin merges directory contents, so each skill must sit in its own
  # subdirectory; a SKILL.md at the root shadows every other skill.
  agentSkills = pkgs.symlinkJoin {
    name = "agent-skills";
    paths = [
      ./skills
      (pkgs.linkFarm "tuicr-skill" [
        {
          name = "tuicr/SKILL.md";
          path = ../dev/tools/tuicr/SKILL.md;
        }
      ])
    ];
  };
in
{
  config = lib.mkIf config.dev.agents.enable {
    home.file.".agents/skills" = {
      source = agentSkills;
      recursive = true;
    };
  };
}
