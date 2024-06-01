{ pkgs
, lib
, config
, ...
}:
{
  options = {
    system = {
      build = {
        toplevel = lib.mkOption {
          type = lib.types.package;
          readOnly = true;
          description = ''
            Top-level root filesystem for the jumploader.
          '';
        };
      };

      initBinary = lib.mkOption {
        type = lib.types.package;
        description = "The init binary to execute";
      };
    };
  };

  config = {
    system.build.toplevel = pkgs.runCommand "jumploader-build-toplevel" {} ''
      # Create the output
      mkdir $out
      touch $out/JUMPLOADER_ROOT

      # Reference the system path
      ln -s ${config.system.path} $out/sw
      ln -s ${lib.getExe' config.system.initBinary "init"} $out/init
      ln -s ${config.system.build.etc} $out/etc

      # System shell
      mkdir $out/bin
      ln -s ${pkgs.runtimeShell} $out/bin/sh
    '';
  };
}
