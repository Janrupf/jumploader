{
  description = "Super small EFI Linux system to boot into another kexec based system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
  flake-utils.lib.eachDefaultSystem (system: let
    # Get the architecture dependent packages
    evaluator = import ./lib/eval.nix {
      inherit nixpkgs;
      inherit system;

      modules = [
        ./system
      ];
    };

    hostPackages = import nixpkgs { inherit system; };
    qemuHelper = hostPackages.callPackage ./host/qemu.nix;
  in {
    packages = {
      toplevel = evaluator.config.system.build.toplevel;
      initrd = evaluator.config.system.build.initrd;
      kernel = evaluator.config.system.build.kernel;
      kernelWithInitrd = evaluator.config.system.build.kernelWithInitrd;
    };

    apps = rec {
      run-vm = flake-utils.lib.mkApp {
        drv = qemuHelper {
          initrd = "${evaluator.config.system.build.initrd}/${evaluator.config.system.build.initrdFileName}";
          kernel = "${evaluator.config.system.build.kernel}/${evaluator.config.system.build.kernelFileName}";
        };
      };

      run-vm-embedded-initrd = flake-utils.lib.mkApp {
        drv = qemuHelper {
          kernel = "${evaluator.config.system.build.kernelWithInitrd}/${evaluator.config.system.build.kernelFileName}";
        };
      };

      run-vm-uefi = flake-utils.lib.mkApp {
        drv = qemuHelper {
          initrd = "${evaluator.config.system.build.initrd}/${evaluator.config.system.build.initrdFileName}";
          kernel = "${evaluator.config.system.build.kernel}/${evaluator.config.system.build.kernelFileName}";
          uefi = true;
        };
      };

      run-vm-uefi-embedded-initrd = flake-utils.lib.mkApp {
        drv = qemuHelper {
          kernel = "${evaluator.config.system.build.kernelWithInitrd}/${evaluator.config.system.build.kernelFileName}";
          uefi = true;
        };
      };

      default = run-vm;
    };
  });
}
