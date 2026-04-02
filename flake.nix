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

    crossOverlay = final: prev: {
      ubootBananaPim2Zero =
        (prev.buildUBoot {
          defconfig = "bananapi_m2_zero_defconfig";
          filesToInstall = ["u-boot-sunxi-with-spl.bin"];
          extraMeta.platforms = ["armv7l-linux"];
        }).overrideAttrs (old: {
          # NOTE: fix for FDT image overlaps OS image (OS=42000000..4308b200)
          postPatch = ''
            ${old.postPatch or ""}
            substituteInPlace include/configs/sunxi-common.h --replace-fail 'SDRAM_OFFSET(3000000)' 'SDRAM_OFFSET(5000000)'
          '';
        });

      python311 = prev.python311.override {
        packageOverrides = pself: psuper: {
          # NOTE: fix libcurl.so: file not recognized: file format not recognized
          pycurl = psuper.pycurl.overrideAttrs (old: {
            preConfigure = ''
              ${old.preConfigure}
              export PYCURL_CURL_CONFIG="${final.curl.dev}/bin/curl-config"
            '';
          });

          # NOTE: fix libgeos_c.so: file not recognized: file format not recognized
          shapely = psuper.shapely.overrideAttrs (old: {
            preConfigure = ''
              ${old.preConfigure or ""}
              export GEOS_CONFIG="${final.geos}/bin/geos-config"
            '';
          });
        };
      };
    };

    klipperFirmware = pkgs:
      (pkgs.klipper-firmware.override {
        firmwareConfig = ./klipper/mcu;
      }).overrideAttrs (old: {
        # NOTE: fix unwind-arm.c:(.text.get_eit_entry+0x94): undefined reference to `__exidx_end'
        nativeBuildInputs = [pkgs.gcc-arm-embedded-11] ++ (old.nativeBuildInputs);
      });
  in {
    devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
      buildInputs = with nixpkgs.legacyPackages.x86_64-linux; [
        klipper-genconf
      ];
    };

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
          printerAgenixKey = pkgs.writeText "printer-agenix-key" (builtins.readFile /home/ksevelyar/.ssh/guest_ed25519_key);
        in {
          imports = [
            (modulesPath + "/installer/sd-card/sd-image.nix")
            (modulesPath + "/profiles/minimal.nix")
          ];

          hardware.deviceTree = {
            enable = true;
            name = "sun8i-h2-plus-bananapi-m2-zero.dtb";
            overlays = [
              {
                name = "uart3-enable";
                filter = "*bananapi-m2-zero*.dtb";
                dtsText = ''
                  /dts-v1/;
                  /plugin/;
                  / {
                    compatible = "allwinner,sun8i-h2-plus";
                    fragment@0 {
                      target = <&uart3>;
                      __overlay__ {
                        pinctrl-names = "default";
                        pinctrl-0 = <&uart3_pins>;
                        status = "okay";
                      };
                    };
                    fragment@1 {
                      target = <&spi1>;
                      __overlay__ {
                        status = "disabled";
                      };
                    };
                    fragment@2 {
                      target-path = "/aliases";
                      __overlay__ {
                        serial3 = "/soc/serial@1c28c00";
                      };
                    };
                  };
                '';
              }
            ];
          };

          age = {
            identityPaths = ["/root/.ssh/printer-agenix-key"];
            secrets.wifi.file = ./secrets/wifi.age;
            secrets.root-password.file = ./secrets/root-password.age;
          };

          nixpkgs = {
            config.allowUnsupportedSystem = true;
            crossSystem.system = "armv7l-linux";
            overlays = [crossOverlay];
          };

          system.stateVersion = "24.05";

          boot = {
            consoleLogLevel = 1;
            loader.grub.enable = false;
            loader.generic-extlinux-compatible.enable = true;
            kernelPackages = pkgs.linuxPackagesFor pkgs.linux_latest;
            kernelParams = ["console=tty0"];
            supportedFilesystems = lib.mkForce ["vfat" "ext4"];
          };

          documentation.enable = false;
          documentation.man.generateCaches = false;
          services.lvm.enable = false;

          environment.systemPackages = with pkgs; [
            android-tools
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
            bottom
            macchina
            usbutils
            dtc
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

          # NOTE: upload big files via fluid
          services.nginx.clientMaxBodySize = "100m";

          networking.firewall = {
            enable = true;
            allowedTCPPorts = [80];
          };
          services.fluidd = {
            enable = true;
            hostName = "printer.local";
          };

          users.users.moonraker.extraGroups = ["klipper"];
          security.polkit.enable = true;

          services.moonraker = {
            enable = true;
            address = "0.0.0.0";
            allowSystemControl = true;
            settings = {
              # NOTE: allow file upload from slicer
              octoprint_compat = {};
              authorization = {
                force_logins = false;
                trusted_clients = ["0.0.0.0/0"];
                cors_domains = ["*"];
              };
              file_manager = {
                enable_object_processing = true;
              };
            };
          };

          # Unable to create log file at '/var/lib/moonraker/logs/moonraker.log'
          systemd.tmpfiles.rules = [
            "d /var/lib/moonraker/logs 0775 moonraker moonraker -"
          ];

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
              extraGroups = ["wheel" "dialout"];
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
              cp "${printerAgenixKey}" ./files/root/.ssh/printer-agenix-key
              chmod 600 ./files/root/.ssh/printer-agenix-key

              mkdir -p ./files/boot
              ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
            '';
            populateFirmwareCommands = "echo 'NOTE: not used, but still required for sdImage 🐗'";
            postBuildCommands = "dd if=${pkgs.ubootBananaPim2Zero}/u-boot-sunxi-with-spl.bin of=$img bs=1024 seek=8 conv=notrunc";
            compressImage = false;
          };
        })
      ];
    };
  };
}
