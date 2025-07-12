{ config, pkgs, lib, self, ... }: {
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
			"telegram"
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

  # Shell configuration
  # programs.zsh = {
  #   enable = true;
  #   enableCompletion = true;
  # };
  programs.fish.enable = true;

  # System metadata
  system.configurationRevision = self.rev or self.dirtyRev or null;
  system.stateVersion = 6;
  nixpkgs.hostPlatform = "aarch64-darwin";

  # User configuration
  users.users.mark = {
    home = "/Users/mark";
    shell = pkgs.fish;
  };
}
