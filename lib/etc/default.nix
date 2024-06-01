# Custom module for /etc
{ config
, pkgs
, lib
, ...
}:
let
  finalEtc = lib.filter (file: file.enable) (lib.attrValues config.environment.etc);
  etcJson = pkgs.writeText "etc.json" (builtins.toJSON finalEtc);

  builderPython = pkgs.buildPackages.python3.withPackages (ps: []);

  builtEtc = pkgs.runCommand "build-etc" {} ''
    ${lib.getExe builderPython} ${./build.py} ${etcJson} $out
  '';
in
{
  options = {
    system.build.etc = lib.mkOption {
      internal = true;
    };

    environment.etc = lib.mkOption {
      default = {};
      description = ''
        Set of files that have to be linked in {file}`/etc`
      '';

      type = lib.types.attrsOf (lib.types.submodule (
        { name, config, options, ... }:
        {
          options = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = ''
                Whether this file should be generated.
              '';
            };

            target = lib.mkOption {
              type = lib.types.str;
              description = ''
                The name of the symlink relative to {file}`/etc`.

                If not set, the name of the attribute will be used.
              '';
            };

            text = lib.mkOption {
              default = null;
              type = lib.types.nullOr lib.types.lines;
              description = ''
                The content of the file.
              '';
            };

            source = lib.mkOption {
              type = lib.types.path;
              description = "Path of the source file.";
            };

            mode = lib.mkOption {
              type = lib.types.str;
              default = "symlink";
              description = ''
                The file mode to set to the target file.

                If set to symlink, then the file will be a symlink
                to the source file. (default)
              '';
            };
          };

          config = {
            target = lib.mkDefault name;
            source = lib.mkIf (config.text != null) (
              let name' = "etc-" + lib.replaceStrings ["/"] ["-"] name;
              in lib.mkDerivedConfig options.text (pkgs.writeText name')
            );
          };
        }
      ));
    };
  };

  config = {
    system.build.etc = builtEtc;
  };
}
