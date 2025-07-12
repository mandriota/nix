{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    { self, fenix, nix-darwin, nixpkgs, home-manager, nix-homebrew }@inputs:
    let
      commonConfig = { pkgs, lib, ... }: {
        nixpkgs.overlays = [ fenix.overlays.default ];

        environment.systemPackages = with pkgs; [
          vim
          ((emacsPackagesFor (emacs.override {
            withNativeCompilation = false;
          })).emacsWithPackages (epkgs: [ epkgs.jinx ]))

          git
          git-filter-repo

					ffmpeg
          iconv
          gnuplot
          graphviz
          readline

          gnupg

          gcc
          go
          (pkgs.fenix.complete.withComponents [
            "cargo"
            "clippy"
            "rust-src"
            "rustc"
            "rustfmt"
          ])
          rust-analyzer-nightly
          taplo-lsp
          guile
          nixfmt-classic

          bear
          tokei

          fish
          zoxide
          fzf

					fastfetch

          libqalculate
        ];

        nix.settings.experimental-features = [ "nix-command" "flakes" ];
      };

      darwinConfig = { pkgs, lib, ... }: {
        nix.linux-builder.enable = true;

        environment.systemPackages = with pkgs; [
          openjdk
          poetry
          python3
          nodejs

          qemu
          (callPackage ./pkgs/knockknock { })
        ];

        # Homebrew configuration
        environment.variables.HOMEBREW_NO_ANALYTICS = "1";
        homebrew = {
          enable = true;
          casks = [
            "playcover-community"
            "megasync"
            "lulu"
            "onlyoffice"
            "krtirtho/apps/spotube"
            "krita"
            "altserver"
          ];
          brews = [ "smartmontools" "enchant" ];
        };

        # Key remapping
        #
        # | From      | To           |
        # |-----------+--------------|
        # | Caps Lock | Left Control |
        # | Tab       | Escape       |
        # | Escape    | Tab          |
        launchd.user.agents.remap-keys = {
          serviceConfig = {
            ProgramArguments = [
              "/usr/bin/hidutil"
              "property"
              "--set"
              ''
                {
                  "UserKeyMapping":[
                    {"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0},
                    {"HIDKeyboardModifierMappingSrc":0x70000002B,"HIDKeyboardModifierMappingDst":0x700000029},
                    {"HIDKeyboardModifierMappingSrc":0x700000029,"HIDKeyboardModifierMappingDst":0x70000002B}
                  ]
                }''
            ];
            RunAtLoad = true;
          };
        };

        # macOS system defaults
        system.defaults = {
          dock = {
            autohide = true;
            mru-spaces = false;
            # Hot corners
            wvous-bl-corner = 1; # bottom-left corner  : disabled
            wvous-br-corner = 1; # bottom-right corner : disabled
            wvous-tl-corner = 1; # top-left corner     : disabled
            wvous-tr-corner = 1; # top-right corner    : disabled
          };

          finder = {
            AppleShowAllExtensions = true;
            AppleShowAllFiles = true;
            CreateDesktop = false;
            FXEnableExtensionChangeWarning = false;
            FXDefaultSearchScope = "SCcf";
            FXPreferredViewStyle = "Nlsv";
            NewWindowTarget = "Other";
            NewWindowTargetPath = "~/";
            QuitMenuItem = true;
            ShowExternalHardDrivesOnDesktop = false;
            ShowRemovableMediaOnDesktop = false;
            ShowStatusBar = true;
            _FXShowPosixPathInTitle = true;
            _FXSortFoldersFirst = true;
          };

          hitoolbox.AppleFnUsageType = "Do Nothing";

          loginwindow = {
            DisableConsoleAccess = true;
            GuestEnabled = false;
            SHOWFULLNAME = true;
          };

          NSGlobalDomain.AppleShowScrollBars = "WhenScrolling";

          menuExtraClock.Show24Hour = true;

          screencapture.location = "~/Pictures/screen";

          trackpad = {
            ActuationStrength = 0;
            Clicking = true;
          };
        };

        home-manager.users.mark = {
          home.stateVersion = "25.05";
          programs = {
            fish = {
              enable = true;
              shellAliases = {
                th = "trash";
                dr = "sudo darwin-rebuild switch --flake $HOME/.config/nix";
              };
              interactiveShellInit = ''
                fish_default_key_bindings
                bind \cr 'history | fzf --tac | read -l result; and commandline -- $result'
              '';
            };
            zoxide = {
              enable = true;
              enableFishIntegration = true;
            };
            fzf = {
              enable = true;
              enableFishIntegration = true;
            };
          };
        };

        programs.fish.enable = true;

        # System metadata
        system.configurationRevision = self.rev or self.dirtyRev or null;
        system.stateVersion = 6;
				system.primaryUser = "mark";
        nixpkgs.hostPlatform = "aarch64-darwin";

        # User configuration
        users.users.mark = {
          home = "/Users/mark";
          shell = pkgs.fish;
        };
      };

      nixosConfig = { config, lib, pkgs, home-manager, ... }:
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
          hardware.graphics.extraPackages = with pkgs; [
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
        };

    in {
      # $ darwin-rebuild build --flake .#spectral
      darwinConfigurations.spectral = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = inputs;
        modules = [
          commonConfig
          darwinConfig
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = "mark";
            };
          }

          ({ pkgs, ... }: {
            environment.variables = { LIBRARY_PATH = "${pkgs.libiconv}/lib"; };
          })
        ];
      };

      nixosConfigurations.kururu = nixpkgs.lib.nixosSystem {
        specialArgs = inputs;
        modules = [ 
          commonConfig
          nixosConfig
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.ku = import ./home.nix;
          }
        ];
      };
    };
}
