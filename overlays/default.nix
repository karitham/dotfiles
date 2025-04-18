_: prev: {
  pokego = prev.callPackage ../pkgs/pokego.nix {};
  golangci-lint = prev.golangci-lint.overrideAttrs (old: rec {
    version = "2.1.2";
    src = prev.fetchFromGitHub {
      owner = "golangci";
      repo = "golangci-lint";
      rev = "v${version}";
      hash = "sha256-CAO+oo3l3mlZIiC1Srhc0EfZffQOHvVkamPHzSKRSFw=";
    };
    vendorHash = "sha256-2GQp/sgYRlDengx8uy3zzqi9hwHh4CQUHoj1zaxNNLE=";
  });
  golangci-lint-langserver = prev.golangci-lint-langserver.overrideAttrs (old: {
    src = prev.fetchFromGitHub {
      owner = "karitham";
      repo = "golangci-lint-langserver";
      rev = "main";
      hash = "sha256-y+A20gb5gw4yOfzQWniKRw4BmZT3gXBwRW+HZN31xd8=";
    };
    vendorHash = "sha256-SsGw26y/ZIBFp9dBk55ebQgJiLWOFRNe21h6huYE84I=";
  });
  gotools = prev.gotools.overrideAttrs (old: {
    patches = prev.fetchurl {
      url = "https://github.com/karitham/gotools/commit/97818d312ebfc0e879de489035dee88e910fd95d.patch";
      hash = "sha256-2EYyelh/NmeO9PuCr5xlx9HhRrqfEjseXB7WLvdrJes=";
    };
    vendorHash = "sha256-+jhCNi7bGkRdI1Ywfe3q4i+zcm3UJ0kbQalsDD3WkS4=";
  });

  powermenu = prev.writeShellScriptBin "powermenu" ''
    declare -rA power_menu=(
        ["  Lock"]="${prev.systemd}/bin/loginctl lock-sessions"
        ["  Sleep"]='systemctl suspend'
        ["  Shut down"]="systemctl poweroff"
        ["  Reboot"]="systemctl reboot"
    )

    set -e -x
    selected_option=$(printf '%s\n' "''${!power_menu[@]}" | fuzzel -d)

    if [[ -n $selected_option ]] && [[ -v power_menu[$selected_option] ]]; then
        eval "''${power_menu[$selected_option]}"
    fi
  '';
}
