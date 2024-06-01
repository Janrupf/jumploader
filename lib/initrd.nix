{ nixpkgs
, pkgs
, config
, lib
, ...
}:
let
  # Proxy init script beacuse make-initrd-ng can't handle an already
  # complete tree
  enter-jumploader-env = pkgs.writeShellScript "enter-jumploader-env" ''
    PATH=/jumploader/sw/bin

    /jumploader/sw/bin/echo "STARTING JUMPLOADER"

    # Mount devtmpfs so we have device nodes available
    mkdir -p /dev
    /jumploader/sw/bin/mount -t devtmpfs none /dev
    
    # Properly chroot into the actual jumploader environment
    mkdir -p /jumploader/dev
    mkdir -p /jumploader/nix

    mount --bind /dev /jumploader/dev
    mount --bind /nix /jumploader/nix

    exec /jumploader/sw/bin/chroot /jumploader /init
  '';

  make-initrd-ng = pkgs.callPackage (nixpkgs + "/pkgs/build-support/kernel/make-initrd-ng.nix") {
    compressor = "cat"; # Will be embedded into the kernel and thus compressed by it
    extension = ".cpio";
    prepend = [ ./dev.cpio ]; # Make sure we have a console device in our cpio
    contents = [
      {
        object = config.system.build.toplevel;
        symlink = "/jumploader";
      } 
      {
        object = enter-jumploader-env;
        symlink = "/init";
      }
    ];
  };
in
{
  options = {
    system.build.initrd = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = ''
        The initrd linked into the jumploader image.
      '';
    };

    system.build.initrdFileName = lib.mkOption {
      type = lib.types.str;
      internal = true;
      default = "initrd.cpio";
    };
  };

  config = {
    system.build.initrd = make-initrd-ng;
  };
}
