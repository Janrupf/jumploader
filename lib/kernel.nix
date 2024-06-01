{
  # Doesn't matter for the kernel, prevents uneccessary recompiles
  #
  # If we use pkgs which has been overwritten to use musl packages,
  # the kernel gets recompiled even if no configuration adjustments
  # have been made. Using the original pkgs prevents that.
  pkgsDynamic
, pkgs
, lib
, config
, ...
}:
let
  inherit (config.boot.kernelPackages) kernel;
in
{
  options = {
    boot.kernelPackages = lib.mkOption {
      type = lib.types.raw;
      default = pkgsDynamic.linuxPackages;
      description = "The linux kernel packages to use";
    };

    system.build.kernel = lib.mkOption {
      type = lib.types.package;
      internal = true;
    };

    system.build.kernelWithInitrd = lib.mkOption {
      type = lib.types.package;
      internal = true;
    };

    system.build.kernelFileName = lib.mkOption {
      type = lib.types.str;
      internal = true;
      default = pkgsDynamic.stdenv.hostPlatform.linux-kernel.target;
    };
  };

  config = {
    system.build.kernel = kernel;
    system.build.kernelWithInitrd = config.system.build.kernel.override (prev: {
      # Can't use kernelPatches: https://github.com/NixOS/nixpkgs/issues/307014
      configfile = pkgs.writeText "kernel-config" (lib.strings.concatLines [
        (builtins.readFile prev.configfile)
        "CONFIG_INITRAMFS_SOURCE=\"${config.system.build.initrd + "/${config.system.build.initrdFileName}"}\""
      ]);
    });
  };
}
