{ nixpkgs
, system
, modules
, ...
}:
let
  pkgs = import nixpkgs { inherit system; };

  baseModules = [
    # Partial set of NixOS modules
    (nixpkgs + "/nixos/modules/misc/nixpkgs.nix")
    (nixpkgs + "/nixos/modules/misc/assertions.nix")

    # For building the root file system
    ./etc
    ./toplevel.nix
    ./path.nix
    ./initrd.nix
    ./kernel.nix

    ({ ... }: {
      # Inline helper module
      nixpkgs.hostPlatform = system;
      nixpkgs.pkgs = pkgs.pkgsStatic;
    })
  ];

  # Evaluated system configuration
  evaluated = pkgs.lib.evalModules {
    prefix = [];

    modules = modules ++ baseModules;

    specialArgs = {
      inherit nixpkgs;
      pkgsDynamic = pkgs;
    };
  };
in {
  config = evaluated.config;
}
