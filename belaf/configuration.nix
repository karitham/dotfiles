{
  config,
  pkgs,
  ghostty,
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
    input-fonts
    nerdfonts
    meslo-lgs-nf
  ];

  # Bootloader.
  boot.supportedFilesystems = ["bcachefs"];
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  networking.hostName = "belaf"; # Define your hostname.
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
  hardware.pulseaudio.enable = false;
  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot =
    true; # powers up the default Bluetooth controller on boot

  services = {
    # sound
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

    # udev
    udev.packages = [pkgs.via];
  };

  hardware.keyboard.qmk.enable = true;

  security = {
    sudo.wheelNeedsPassword = false;
    rtkit.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    defaultUserShell = pkgs.zsh;
    users.kar = {
      isNormalUser = true;
      description = "kar";
      extraGroups = ["networkmanager" "wheel" "docker"];
      home = "/home/kar";
    };
  };

  # shell setup
  programs.zsh = {
    enable = true;
    shellInit = "export PATH=${config.users.users.kar.home}/go/bin:$PATH";
    ohMyZsh = {
      enable = true;
      plugins = ["sudo" "zsh-navigation-tools" "zoxide"];
    };
  };

  programs.ssh.startAgent = true;
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = with pkgs; {
    shells = [zsh];

    systemPackages = [
      ghostty.packages."${system}".default
      armcord
      vscode
      spotify
      spicetify-cli
      tailscale
      helix
      fzf
      difftastic
      firefox
      chromium
      zsh
      zoxide
      vim
      curl
      wget
      ripgrep
      jq
      eza
      alejandra
      mpv
      moreutils
      age
      nix-output-monitor
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
    data-root = "/docker";
  };
  virtualisation.docker.daemon.settings = {
    shutdown-timeout = 2;
  };
}
