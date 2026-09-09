{
  description = "NixOS sdImage for Banana Pi M2 Zero";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
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
      pkgs.klipper-firmware.override {
        firmwareConfig = ./klipper/mcu;
      };
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
        (import ./banana-pi-m2-zero.nix)
        ({
          pkgs,
          modulesPath,
          config,
          ...
        }: let
          gcodeShellCommandPy = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/dw-0/kiauh/master/kiauh/extensions/gcode_shell_cmd/assets/gcode_shell_command.py";
            sha256 = "sha256-WTcKHi+2BNRnLBxBueJmkG5Zb9zfr+RvXPeQSJWEHSk=";
          };

          klipperWithShellCommand = pkgs.klipper.overrideAttrs (old: {
            postInstall =
              (old.postInstall or "")
              + ''
                cp ${gcodeShellCommandPy} $out/lib/klipper/extras/gcode_shell_command.py
              '';
          });
        in {
          imports = [
            (modulesPath + "/installer/sd-card/sd-image.nix")
            (modulesPath + "/profiles/minimal.nix")
          ];

          age = {
            identityPaths = ["/root/.ssh/printer-agenix-key"];
            secrets.wifi.file = ./secrets/wifi.age;
            secrets.wifi.owner = "wpa_supplicant";
            secrets.wifi.group = "wpa_supplicant";
            secrets.root-password.file = ./secrets/root-password.age;
          };

          nixpkgs = {
            config.allowUnsupportedSystem = true;
            crossSystem.system = "armv7l-linux";
          };

          system.stateVersion = "24.05";

          boot = {
            consoleLogLevel = 1;
            loader.grub.enable = false;
            loader.generic-extlinux-compatible.enable = true;
            kernelParams = ["console=tty0"];
            supportedFilesystems = lib.mkForce ["vfat" "ext4"];
          };

          documentation.enable = false;
          documentation.man.cache.enable = false;
          services.lvm.enable = false;

          environment.systemPackages = with pkgs; [
            bashInteractive
            fish
            openssh
            android-tools
            tmux
            neovim-unwrapped
            rsync
            gitMinimal
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

          # NOTE: minimize sd card writes
          services.journald.storage = "volatile";
          boot.tmp.useTmpfs = true;
          boot.tmp.tmpfsSize = "50M";
          fileSystems."/".options = [ "noatime" "commit=60" ];

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
            package = klipperWithShellCommand;
            logFile = "/tmp/klipper.log";
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
          fileSystems."/var/lib/moonraker/logs" = {
            device = "none";
            fsType = "tmpfs";
            options = [ "defaults" "mode=0775" ];
          };

          services.fluidd = {
            enable = true;
            hostName = "printer.local";
          };

          users.users.moonraker.extraGroups = ["klipper" "adbusers"];
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
              extraGroups = ["wheel" "dialout" "adbusers"];
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
              extraConfig = "country=RU";
              networks.skynet-2 = {
                pskRaw = "ext:SKYNET_2";
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
        })
      ];
    };
  };
}
