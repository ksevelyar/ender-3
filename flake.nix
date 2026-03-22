{
  description = "NixOS sdImage for Banana Pi M2 Zero";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    agenix.url = "github:ryantm/agenix/caab0435e181becfd66c24e5ea5ae56ac837afbe";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    nixpkgs,
    agenix,
    ...
  }: let
    lib = nixpkgs.lib;

    klipperFirmware = pkgs:
      (pkgs.klipper-firmware.override {
        firmwareConfig = ./klipper/mcu;
      }).overrideAttrs (old: {
        # NOTE: versions >11 are broken for armv7l-linux
        nativeBuildInputs = [pkgs.gcc-arm-embedded-11] ++ (old.nativeBuildInputs or []);
      });
  in {
    packages.x86_64-linux.klipper-firmware = klipperFirmware nixpkgs.legacyPackages.x86_64-linux;

    nixosConfigurations.printer = lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        agenix.nixosModules.default
        ({
          pkgs,
          modulesPath,
          config,
          ...
        }: let
          printerKey = pkgs.writeText "printer-agenix-key" (builtins.readFile /home/ksevelyar/.ssh/guest_ed25519_key);
        in {
          imports = [
            (modulesPath + "/installer/sd-card/sd-image.nix")
            (modulesPath + "/profiles/minimal.nix")
          ];

          age = {
            identityPaths = ["/root/.ssh/printer-agenix-key"];
            secrets.wifi.file = ./secrets/wifi.age;
            secrets.root-password.file = ./secrets/root-password.age;
          };

          system.stateVersion = "24.05";
          nixpkgs = {
            config.allowUnsupportedSystem = true;
            crossSystem.system = "armv7l-linux";
            overlays = [
              (final: prev: {
                ubootBananaPim2Zero =
                  (prev.buildUBoot {
                    defconfig = "bananapi_m2_zero_defconfig";
                    filesToInstall = ["u-boot-sunxi-with-spl.bin"];
                    extraMeta.platforms = ["armv7l-linux"];
                  }).overrideAttrs (old: {
                    # Fix for: ERROR: FDT image overlaps OS image (OS=42000000..4308b200)
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

          boot = {
            consoleLogLevel = 1;
            loader.grub.enable = false;
            loader.generic-extlinux-compatible.enable = true;
            loader.generic-extlinux-compatible.configurationLimit = 1;
            kernelPackages = pkgs.linuxPackagesFor pkgs.linux_latest;
            kernelParams = ["console=tty0"];
            supportedFilesystems = lib.mkForce ["vfat" "ext4"];
          };

          documentation.enable = false;
          documentation.man.generateCaches = false;
          environment.systemPackages = with pkgs; [
            tmux
            vim
            rsync
            git
            lm_sensors
            powertop
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
          nix.extraOptions = "experimental-features = nix-command flakes";

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
            # NOTE: not supported for armv7l-linux
            firmwares.mcu.enable = false;
            configFile = ./klipper/printer.cfg;
          };
          users.users.klipper = {
            isSystemUser = true;
            group = "klipper";
            extraGroups = ["dialout"];
          };
          users.groups.klipper = {};
          services.fluidd.enable = true;

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
              environmentFile = config.age.secrets.wifi.path;
              networks.skynet-2 = {
                psk = "@SKYNET_2@";
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
              mkdir -p ./files/root/.ssh
              chmod 700 ./files/root/.ssh
              cp "${printerKey}" ./files/root/.ssh/printer-agenix-key
              chmod 600 ./files/root/.ssh/printer-agenix-key

              mkdir -p ./files/boot
              ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
            '';

            populateFirmwareCommands = ''
              echo "🐗"
            '';

            postBuildCommands = ''
              dd if=${pkgs.ubootBananaPim2Zero}/u-boot-sunxi-with-spl.bin of=$img bs=1024 seek=8 conv=notrunc
            '';
            compressImage = false;
          };
        })
      ];
    };
  };
}
