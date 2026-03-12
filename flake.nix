{
  description = "NixOS sdImage for Banana Pi M2 Zero (Allwinner H2+)";

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
            (modulesPath + "/installer/sd-card/sd-image-armv7l-multiplatform.nix")
            (modulesPath + "/profiles/minimal.nix")
          ];

          documentation.enable = false;

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

          boot.supportedFilesystems = lib.mkForce [
            "vfat"
            "ext4"
          ];

          hardware.enableRedistributableFirmware = true;

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

          sdImage.populateFirmwareCommands = let
            uboot = pkgs.buildUBoot {
              defconfig = "bananapi_m2_zero_defconfig";
              extraMeta.platforms = ["armv7l-linux"];
              filesToInstall = ["u-boot-sunxi-with-spl.bin"];
            };
          in
            lib.mkForce ''
              cp ${uboot}/u-boot-sunxi-with-spl.bin firmware/u-boot-sunxi-with-spl.bin
            '';

          sdImage.postBuildCommands = lib.mkForce ''
            dd if=firmware/u-boot-sunxi-with-spl.bin of=$img bs=1024 seek=8 conv=notrunc
          '';
        })
      ];
    };

    packages.${buildSystem} = {
      sdImage = self.nixosConfigurations.bpi-m2-zero.config.system.build.sdImage;
    };
  };
}
