{ pkgs
, kernel
, initrd ? null
, lib
, uefi ? false
, ...
}:
let
  uefiVFS = pkgs.runCommand "make-qemu-efi-vfs" {} ''
    mkdir $out
    cp ${kernel} $out/kernel.efi
    ${lib.optionalString (initrd != null) "cp ${initrd} $out/initrd.img"}

    echo "\\kernel.efi ${lib.optionalString (initrd != null) "\\initrd=initrd.img"}" > "$out/startup.nsh"
  '';

  qemuBootPrepare = if uefi
    then ''
      EFI_TMP=/tmp/qemu-efi
      rm -rf $EFI_TMP
      cp -r ${uefiVFS} $EFI_TMP

      for x in $(find "$EFI_TMP"); do
        chmod +w $x
      done
    ''
    else ''
    '';

  qemuBootArgs = if uefi
    then ''
      -drive "if=pflash,format=raw,readonly=on,file=${pkgs.OVMF.fd}/FV/OVMF.fd" \
      -drive "file=fat:rw:$EFI_TMP" \
    ''
    else ''
      -kernel ${kernel} \
      ${lib.optionalString (initrd != null) "-initrd ${initrd}"} \
    '';
in
pkgs.writeShellScriptBin "run-jumploader" ''
  echo "Kernel at ${kernel}"

  ${qemuBootPrepare}

  exec ${pkgs.qemu_kvm}/bin/qemu-kvm \
    -net none \
    -m 128M \
    ${qemuBootArgs} \
    -cpu host
''
