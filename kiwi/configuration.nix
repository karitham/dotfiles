{
  config,
  pkgs,
  ...
}: {
  nix.settings = {
    trusted-users = ["root" "kar"];
    experimental-features = ["nix-command" "flakes"];
    auto-optimise-store = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  # Allow unfree packages
  nixpkgs.config = {
    allowUnfree = true;
    input-fonts.acceptLicense = true;
  };

  fonts.packages = with pkgs; [
    victor-mono
    nerd-fonts.martian-mono
    nerd-fonts.jetbrains-mono
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  networking.hostName = "kiwi"; # Define your hostname.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "en_US.utf8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.utf8";
    LC_IDENTIFICATION = "fr_FR.utf8";
    LC_MEASUREMENT = "fr_FR.utf8";
    LC_MONETARY = "fr_FR.utf8";
    LC_NAME = "fr_FR.utf8";
    LC_NUMERIC = "fr_FR.utf8";
    LC_PAPER = "fr_FR.utf8";
    LC_TELEPHONE = "fr_FR.utf8";
    LC_TIME = "fr_FR.utf8";
  };

  # disable pulse because pipewire handles it
  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot =
    true; # powers up the default Bluetooth controller on boot

  services.pcscd.enable = true;
  programs.gnupg.agent = {
    enable = true;
  };
  services = {
    # sound
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };

    tailscale.enable = true;
    tailscale.useRoutingFeatures = "client";

    # touchpad
    touchegg.enable = true;

    # bluetooth
    blueman.enable = true;
  };

  security = {
    sudo.wheelNeedsPassword = false;
    rtkit.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    defaultUserShell = config.shell.pkg;
    users.kar = {
      isNormalUser = true;
      description = "kar";
      extraGroups = ["networkmanager" "wheel" "docker"];
      home = "/home/kar";
    };
  };

  programs.ssh.startAgent = true;
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = with pkgs; {
    shells = ["/run/current-system/sw/bin/${config.shell.name}" "${config.shell.pkg}/bin/${config.shell.name}"];
    variables = {
      EDITOR = "hx";
    };
    systemPackages = [
      legcord
      vscode
      spotify
      tailscale
      helix
      fzf
      difftastic
      chromium
      vim
      curl
      wget
      ripgrep
      jq
      eza
      sd
      alejandra
      mpv
      busybox
      moreutils
      age
    ];
    etc = {
      "xdg/gtk-3.0/settings.ini".text = ''
        [Settings]
        gtk-application-prefer-dark-theme=1
      '';
      "xdg/gtk-4.0/settings.ini".text = ''
        [Settings]
        gtk-application-prefer-dark-theme=1
      '';
    };
  };

  virtualisation.docker.enable = true;
  virtualisation.docker.daemon.settings = {
    shutdown-timeout = 2;
  };
}
