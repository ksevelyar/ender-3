# NOTE: Banana Pi M2 Zero specifics: soc fixes, device tree, u-boot, sd image
{
  pkgs,
  modulesPath,
  config,
  ...
}: {
  nixpkgs.overlays = [
    (final: prev: {
      ubootBananaPim2Zero =
        (prev.buildUBoot {
          defconfig = "bananapi_m2_zero_defconfig";
          filesToInstall = ["u-boot-sunxi-with-spl.bin"];
          extraMeta.platforms = ["armv7l-linux"];
        }).overrideAttrs (old: {
          # NOTE: u-boot (FDT overlaps OS image without SDRAM_OFFSET fix)
          postPatch = ''
            ${old.postPatch or ""}
            substituteInPlace include/configs/sunxi-common.h --replace-fail 'SDRAM_OFFSET(3000000)' 'SDRAM_OFFSET(5000000)'
          '';
        });

      # NOTE: cross gcc defaults to vfpv3-d16, openblas ARMV7 kernels need d16-d31
      openblas =
        if prev.stdenv.hostPlatform.isAarch32
        then prev.openblas.overrideAttrs (old: {
          cmakeFlags = (old.cmakeFlags or []) ++ [
            "-DCMAKE_C_FLAGS=-mfpu=neon-vfpv4"
            "-DCMAKE_ASM_FLAGS=-mfpu=neon-vfpv4"
          ];
        })
        else prev.openblas;

      # NOTE: xtask (host tool) links armv7 pcre2; docs not needed anyway
      fish = prev.fish.overrideAttrs (old: {
        cmakeFlags = (old.cmakeFlags or []) ++ ["-DWITH_DOCS=OFF"];
        doCheck = false;
        doInstallCheck = false;
      });

      python313 = prev.python313.override {
        packageOverrides = pself: psuper: {
          # NOTE: setup.py picks x86_64 curl-config from PATH
          pycurl = psuper.pycurl.overrideAttrs (old: {
            preConfigure = ''
              ${old.preConfigure}
              export PYCURL_CURL_CONFIG="${final.curl.dev}/bin/curl-config"
            '';
          });

          # NOTE: meson picks x86_64 build python (wrong SIZEOF_LONG in pyconfig.h)
          matplotlib = psuper.matplotlib.overrideAttrs (old: {
            mesonFlags = (old.mesonFlags or []) ++ [
              "--cross-file=${prev.writeText "matplotlib-host-python.ini" ''
                [binaries]
                python = '${psuper.python}/bin/python3.13'
              ''}"
            ];
            # NOTE: pybind11-config runs x86_64 python and injects its include dir
            postPatch = (old.postPatch or "") + ''
              substituteInPlace meson.build --replace-fail \
                "pybind11_dep = dependency('pybind11', version: '>=2.13.2')" \
                "pybind11_dep = dependency('pybind11', version: '>=2.13.2', method: 'pkg-config')"
            '';
            preConfigure = (old.preConfigure or "") + ''
              export PKG_CONFIG_PATH="${psuper.pybind11}/share/pkgconfig''${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
            '';
          });
        };
      };
    })
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

  sdImage = {
    populateRootCommands = ''
      mkdir -p ./files/root/.ssh
      chmod 700 ./files/root/.ssh
      cp "${pkgs.writeText "printer-agenix-key" (builtins.readFile /home/ksevelyar/.ssh/guest_ed25519_key)}" ./files/root/.ssh/printer-agenix-key
      chmod 600 ./files/root/.ssh/printer-agenix-key

      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
    populateFirmwareCommands = "echo 'NOTE: not used, but still required for sdImage 🐗'";
    postBuildCommands = "dd if=${pkgs.ubootBananaPim2Zero}/u-boot-sunxi-with-spl.bin of=$img bs=1024 seek=8 conv=notrunc";
    compressImage = false;
  };
}
