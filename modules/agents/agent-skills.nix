# The agent skills every agent shares, as one directory. OpenCode and albedo
# both read the portable ~/.agents/skills, so it is built once here and linked
# in by whichever install delivers it: home-manager (./skills.nix) or an image
# (./albedo-config.nix).
{ pkgs }:
# symlinkJoin merges directory contents, so each skill must sit in its own
# subdirectory; a SKILL.md at the root shadows every other skill.
pkgs.symlinkJoin {
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
}
