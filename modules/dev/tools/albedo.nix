{ config, lib, ... }: {
  options.dev.albedo.enable = lib.mkEnableOption "the Albedo coding agent";

  # The package comes from modules/agents: albedo is handed the same MCP
  # servers opencode gets, and it needs the agent secrets in its environment.
  config = lib.mkIf config.dev.albedo.enable { home.packages = [ config.dev.agents.albedo.package ]; };
}
