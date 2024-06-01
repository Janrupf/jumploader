{ pkgs
, ...
}:
{
  imports = [
    ./linux
  ];

  config = {
    environment.systemPackages = [
      pkgs.kexec-tools
      pkgs.busybox

      # We need this so we can actually run shell scripts...
      pkgs.runtimeShellPackage
    ];

    system.initBinary = pkgs.busybox;

    environment.etc."init.d/rcS".source = pkgs.writeShellScript "init" ''
      set -e

      export PATH=/sw/bin

      # Mount proc and sys
      mkdir -p /proc
      mkdir -p /sys

      mount -t proc none /proc
      mount -t sysfs none /sys

      # Mount the root filesystem to jump to
      until root_dev="$(findfs LABEL=rootfs)"
      do
        echo "Root file system not found, waiting..."
        sleep 1
      done
      
      root_uuid="$(blkid "$root_dev" | sed -nr 's/.*(UUID=")(.*)" .*$/\2/p')"

      mkdir -p /mnt
      mount -o ro "$root_dev" /mnt

      # Load the kernel and initrd
      kexec \
        -l /mnt/boot/vmlinuz \
        --initrd=/mnt/boot/initrd.img \
        --append="root=UUID=$root_uuid sdhci.debug_quirks2=4"
      
      # Boot the kernel
      exec kexec -e
    '';
  };
}
