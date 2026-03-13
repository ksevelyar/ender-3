{
  description = "NixOS sdImage for Banana Pi M2 Zero (Allwinner H3)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    agenix,
    ...
  }: let
    buildSystem = "x86_64-linux";
    lib = nixpkgs.lib;
  in {
    nixosConfigurations.bpi-m2-zero = lib.nixosSystem {
      system = buildSystem;

      modules = [
        agenix.nixosModules.default

        ({
          pkgs,
          modulesPath,
          config,
          ...
        }: {
          imports = [
            (modulesPath + "/installer/sd-card/sd-image.nix")
            (modulesPath + "/profiles/minimal.nix")
          ];

          boot = {
            consoleLogLevel = 7;
            kernelPackages = pkgs.linuxPackages_latest;
            loader.grub.enable = false;
            loader.generic-extlinux-compatible.enable = true;
            kernelParams = [
              "console=ttyS0,115200n8"
              "console=tty0"
            ];
            supportedFilesystems = lib.mkForce [
              "vfat"
              "ext4"
            ];
          };

          documentation.enable = false;
          documentation.man.generateCaches = false;

          environment.systemPackages = with pkgs; [
            strace
            rsync
          ];

          environment.defaultPackages = [];

          fonts.packages = with pkgs; [
            terminus_font
          ];

          services.avahi = {
            enable = true;
            nssmdns4 = true;
            publish = {
              enable = true;
              userServices = true;
              addresses = true;
              domain = true;
              workstation = true;
            };
          };

          nixpkgs = {
            config.allowUnsupportedSystem = true;
            crossSystem.system = "armv7l-linux";

            overlays = [
              (self: super: {
                efivar = pkgs.runCommand "empty-efivar" {} "mkdir $out";
                efibootmgr = pkgs.runCommand "empty-efibootmgr" {} "mkdir $out";
              })
            ];
          };

          system.stateVersion = "25.11";

          services.openssh = {
            enable = true;
            startWhenNeeded = false;
            settings = {
              PermitRootLogin = "prohibit-password";
              PasswordAuthentication = false;
            };
          };

          users.users = {
            root = {
              openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOrgLo+NfYI06fdY1BamC5o2tNeRlw1ZuPAkyy41w0Ir ksevelyar@gmail.com"
              ];
            };

            ksevelyar = {
              isNormalUser = true;
              openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOrgLo+NfYI06fdY1BamC5o2tNeRlw1ZuPAkyy41w0Ir ksevelyar@gmail.com"
              ];
            };
          };

          environment.etc."ssh/ssh_host_ed25519_key".source = "/home/ksevelyar/.ssh/guest_ed25519_key";
          environment.etc."ssh/ssh_host_ed25519_key".mode = "0600";
          environment.etc."ssh/ssh_host_ed25519_key.pub".source = "/home/ksevelyar/.ssh/guest_ed25519_key.pub";
          environment.etc."ssh/ssh_host_ed25519_key.pub".mode = "0644";

          age.secrets.wifi-skynet-2.file = ./secrets/wifi-skynet-2.age;

          networking = {
            hostName = "printer";
            firewall.enable = false;
            useDHCP = true;
            enableIPv6 = false;

            wireless = {
              enable = true;

              networks."skynet-2" = {
                pskRaw = "ext:${config.age.secrets.wifi-skynet-2.path}";
              };
            };
          };

          sdImage = {
            populateRootCommands = ''
              mkdir -p ./files/boot
              ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
            '';

            populateFirmwareCommands = ''
              cp ${pkgs.ubootBananaPim2Zero}/u-boot-sunxi-with-spl.bin firmware/u-boot-sunxi-with-spl.bin
            '';

            postBuildCommands = ''
                set -e

                dd if=firmware/u-boot-sunxi-with-spl.bin of=$img bs=1024 seek=8 conv=notrunc

                cat > /tmp/uboot-env.txt <<'EOF'
              fdt_addr_r=0x45000000
              EOF

                ${pkgs.buildPackages.ubootTools}/bin/mkenvimage -s 0x4000 -o /tmp/uboot.env /tmp/uboot-env.txt

                dd if=/tmp/uboot.env of=$img bs=1024 seek=1024 conv=notrunc
            '';

            compressImage = false;
          };
        })
      ];
    };

    packages.${buildSystem} = {
      sdImage = self.nixosConfigurations.bpi-m2-zero.config.system.build.sdImage;
    };
  };
}
