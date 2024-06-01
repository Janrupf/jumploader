{ pkgs
, ...
}:
{
  boot.kernelPackages = {
    kernel = pkgs.linuxPackages_custom_tinyconfig_kernel.override {
      configfile = ./kernel.config;
    };
  };
}
