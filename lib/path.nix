{ pkgs
, config
, lib
, ...
}:
{
  options = {
    environment = {
      systemPackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [];
        description = "Packages to make available on the system PATH";
      };
    };

    system.path = lib.mkOption {
      internal = true;
      description = "Final environment containing the system PATH";
    };
  };

  config = {
    system.path = pkgs.buildEnv {
      name = "system-path";
      paths = config.environment.systemPackages;
    };
  };
}