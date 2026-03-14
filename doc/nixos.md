## NixOS

### First install
```
nix build .#sdImage

sudo dd if=result/sd-image/nixos-image-sd-card-25.11.20260304.fabb8c9-armv7l-linux.img of=/dev/sdx bs=4M status=progress conv=fsync
```

## Update
```
nixos-rebuild switch --flake .#printer --target-host root@printer.local
```
