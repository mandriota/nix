{ pkgs, lib, fenix, ... }: {
  nixpkgs.overlays = [ fenix.overlays.default ];

  environment.systemPackages = with pkgs; [
		# text editors
    vim
    ((emacsPackagesFor (emacs.override {
      withNativeCompilation = false;
    })).emacsWithPackages (epkgs: [ epkgs.jinx ]))

		# git
    git
    git-filter-repo

		# library/utils
    ffmpeg
    iconv
    gnuplot
    graphviz
    readline

		# cryptography
    gnupg

		# programming languages tools
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

		# project management
    bear
    tokei

		# shell
    fish
    zoxide
    fzf

		# other
    fastfetch
    libqalculate
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
