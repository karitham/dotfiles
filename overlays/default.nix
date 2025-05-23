_: prev: {
  pokego = prev.callPackage ../pkgs/pokego.nix {};
  golangci-lint-langserver = prev.golangci-lint-langserver.overrideAttrs (old: {
    patches = prev.fetchurl {
      url = "https://github.com/karitham/golangci-lint-langserver/commit/31e6806187d431a8865261b5441ef5a65b589ae5.patch";
      hash = "sha256-Sw7KCsAhShobhvtwS0KeeWL4ewuXuQYyPeaeHKGUs+I=";
    };
    vendorHash = "sha256-kbGTORTTxfftdU8ffsfh53nT7wZldOnBZ/1WWzN89Uc=";
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
