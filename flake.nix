{
  description = "NixOS sdImage for Banana Pi M2 Zero";

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
    nixosConfigurations.printer = lib.nixosSystem {
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

          age = {
            identityPaths = ["/home/ksevelyar/.ssh/guest_ed25519_key"];
            secrets.wifi.file = ./secrets/wifi.age;
            secrets.root-password.file = ./secrets/root-password.age;
          };

          boot = {
            consoleLogLevel = 1;
            loader.grub.enable = false;
            loader.generic-extlinux-compatible.enable = true;
            loader.generic-extlinux-compatible.configurationLimit = 1;
            kernelParams = ["console=ttyS0,115200n8" "console=tty0"];
            supportedFilesystems = lib.mkForce ["vfat" "ext4"];
          };

          documentation.enable = false;
          documentation.man.generateCaches = false;
          environment.systemPackages = with pkgs; [
            rsync
            lm_sensors
            powertop
            vim
            zoxide
            bat
            fd
            fzf
            ripgrep
            tealdeer
            bottom
            macchina
          ];

          environment.defaultPackages = [];

          nix = {
            daemonCPUSchedPolicy = "idle";
            extraOptions = ''
              experimental-features = nix-command flakes
            '';
          };
          nixpkgs = {
            config.allowUnsupportedSystem = true;
            crossSystem.system = "armv7l-linux";

            overlays = [
              (final: prev: {
                python3 = prev.python312;

                klipper = prev.klipper.override {
                  python3 = final.python312;
                };
              })

              # NOTE: patch uboot to use fdt_addr_r=0x45000000
              # fix for ERROR: FDT image overlaps OS image (OS=42000000..4308b200)
              (final: prev: {
                ubootBananaPim2Zero = prev.ubootBananaPim2Zero.overrideAttrs (old: {
                  postPatch =
                    (old.postPatch or "")
                    + ''
                      substituteInPlace include/configs/sunxi-common.h \
                        --replace-fail 'SDRAM_OFFSET(3000000)' 'SDRAM_OFFSET(5000000)'
                    '';
                });
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

          # NOTE: fix setgroups crash on arm
          systemd.services.avahi-daemon.serviceConfig.SystemCallFilter = lib.mkForce [];
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

          services.klipper = {
            enable = true;
            user = "klipper";
            group = "klipper";
            firmwares.mcu = {
              enable = true;
              configFile = ./klipper/mcu;
            };
            configFile = ./klipper/printer.cfg;
          };
          users.users.klipper = {
            isSystemUser = true;
            group = "klipper";
            extraGroups = ["dialout"];
          };
          users.groups.klipper = {};
          services.fluidd = {
            enable = true;
          };

          users.defaultUserShell = pkgs.fish;
          programs.fish.enable = true;
          programs.fish.interactiveShellInit = ''
            set fish_greeting

            set temp (cat /sys/devices/virtual/thermal/thermal_zone0/temp 2>/dev/null)
            test -n "$temp"; and echo "🌡️ "(math -s 0 "$temp / 1000")"C"
          '';

          users.mutableUsers = false;
          users.users = {
            root = {
              openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOrgLo+NfYI06fdY1BamC5o2tNeRlw1ZuPAkyy41w0Ir ksevelyar@gmail.com"
              ];
              hashedPasswordFile = config.age.secrets.root-password.path;
            };

            ksevelyar = {
              isNormalUser = true;
              openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOrgLo+NfYI06fdY1BamC5o2tNeRlw1ZuPAkyy41w0Ir ksevelyar@gmail.com"
              ];
              hashedPasswordFile = config.age.secrets.root-password.path;

              extraGroups = ["wheel"];
            };
          };

          networking = {
            usePredictableInterfaceNames = false;
            hostName = "printer";

            useDHCP = false;
            interfaces.wlan0.useDHCP = true;

            wireless = {
              enable = true;
              secretsFile = config.age.secrets.wifi.path;
              networks."skynet-2" = {
                pskRaw = "ext:skynet-2";
              };
            };
          };

          zramSwap = {
            enable = true;
            algorithm = "zstd";
          };
          hardware.bluetooth.enable = false;
          powerManagement = {
            enable = true;
            cpuFreqGovernor = "powersave";
          };

          sdImage = {
            populateRootCommands = ''
              mkdir -p ./files/boot
              ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
            '';
            populateFirmwareCommands = ''
              ls
            '';

            postBuildCommands = ''
              dd if=${pkgs.ubootBananaPim2Zero}/u-boot-sunxi-with-spl.bin of=$img bs=1024 seek=8 conv=notrunc
            '';

            compressImage = false;
          };
        })
      ];
    };

    packages.${buildSystem} = {
      sdImage = self.nixosConfigurations.printer.config.system.build.sdImage;

      # NOTE: inspect uboot env vars with
      # nix build .#uboot
      # strings result/u-boot-sunxi-with-spl.bin | grep "fdt_addr_r"
      uboot = self.nixosConfigurations.bpi-m2-zero.pkgs.ubootBananaPim2Zero;
    };
  };
}
