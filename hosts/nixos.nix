{ config, lib, pkgs, home-manager, ... }:
let
  commonAliases = {
    ll = "ls -lah";
    la = "ls -la";
  };
in {
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./apple-silicon-support
  ];

  hardware.asahi.peripheralFirmwareDirectory = ./firmware;
  hardware.asahi = {
    enable = true;
    useExperimentalGPUDriver = true;
    # experimentalGPUInstallMode = "replace";
  };
  hardware.graphics.enable = true;
  hardware.graphics.extraPackages = with pkgs;
    [
      # mesa.drivers
    ];
  hardware.enableRedistributableFirmware = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  networking.hostName = ""; # Define your hostname.
  systemd.services.randomize-hostname = {
    description = "Randomize hostname";
    wantedBy = [ "multi-user.target" ];
    before = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "randomize-hostname" ''
        RANDOM_NAME=$(${pkgs.coreutils}/bin/tr -dc 'a-z0-9' < /dev/urandom | ${pkgs.coreutils}/bin/head -c8)

        ${pkgs.util-linux}/bin/hostname "$RANDOM_NAME"
        echo "$RANDOM_NAME" > /proc/sys/kernel/hostname

        ${pkgs.gnused}/bin/sed -i "s/127\.0\.1\.1.*/127.0.1.1 $RANDOM_NAME/" /etc/hosts
      ''}";
    };
  };
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.
  networking.wireless.iwd = {
    enable = true;
    settings.General = {
      EnableNetworkConfiguration = true;
      AddressRandomization = "once";
    };
  };

  # Set your time zone.
  time.timeZone = "Europe/Rome";

  users.mutableUsers = true;
  users.users.recovery = {
    isNormalUser = true;
    description = "Recovery user";
    extraGroups = [ "wheel" ];

    shell = pkgs.bash;
    createHome = false;
  };
  users.users.ku = {
    isNormalUser = true;
    description = "Ku";
    extraGroups = [ "wheel" "video" "render" ];

    shell = pkgs.fish;
  };

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  console = {
    #   font = "Lat2-Terminus16";
    keyMap = "it";
    #   useXkbConfig = true; # use xkb.options in tty.
    colors = [
      "282828"
      "cc241d"
      "98971a"
      "d79921"
      "458588"
      "b16286"
      "689d6a"
      "a89984"

      "928374"
      "fb4934"
      "b8bb26"
      "fabd2f"
      "83a598"
      "d3869b"
      "8ec07c"
      "ebdbb2"
    ];
  };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;
  # services.libinput = {
  #  enable = true;
  #  touchpad = {
  #    naturalScrolling = true;
  #    tapping = true;
  #  };
  #};

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.variant = "intl";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # services.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.alice = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  #   packages = with pkgs; [
  #     tree
  #   ];
  # };

  # programs.firefox.enable = true;
  programs = {
    fish = {
      enable = true;
      shellAliases = commonAliases;
      interactiveShellInit = ''
        fish_default_key_bindings
        bind \cr 'history | fzf --tac | read -l result; and commandline -- $result'
      '';
    };
    bash = { shellAliases = commonAliases; };
    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };
    # fzf = {
    #  enable = true;
    #  enableFishIntegration = true;
    #};
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    waybar.enable = true;
  };

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    home-manager
    alacritty
    kitty
    hyprland
    waybar
    vulkan-tools
    glxinfo
    wayland-utils

    vim
    git
    fzf
    lshw
    glances
    htop
    aspell
    aspellDicts.en
  ];

  environment.shellAliases = {
    nrt = "nixos-rebuild test --flake /etc/nixos#default";
    nrs = "nixos-rebuild switch --flake /etc/nixos#default";
  };

  environment.variables = {
    WLR_RENDERER = "gles2";
    WLR_NO_HARDWARE_CURSORS = "1";
    MESA_LOADER_DRIVER_OVERRIDE = "asahi";
    LIBGL_DRIVERS_PATH = "/run/opengl-driver/lib/dri";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # home-manager.users.ku.wayland.windowManager.hyprland = {
  # enable = true;
  # settings = {
  #  "$mod" = "$SUPER";
  #  bind = [
  #    "$mod, Q, killactive"
  #  ];
  #  monitor = "eDP-1,1920x1200@60,0x0,1";
  #  exec-once = [
  #    "waybar"
  #    "alacritty"
  #  ];
  #};
  #};

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?
  home-manager.users.ku.home.stateVersion = "25.11";
}
