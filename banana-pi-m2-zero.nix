# NOTE: Banana Pi M2 Zero specifics: soc fixes, device tree, u-boot, sd image
{
  pkgs,
  lib,
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
        then
          prev.openblas.overrideAttrs (old: {
            cmakeFlags =
              (old.cmakeFlags or [])
              ++ [
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

      # NOTE: neovim needs only libtree-sitter; skip CLI cargo build (rquickjs bindgen broken on armv7)
      tree-sitter =
        if prev.stdenv.hostPlatform.isAarch32
        then
          prev.stdenv.mkDerivation {
            pname = "tree-sitter";
            version = "0.26.8";
            src = prev.fetchFromGitHub {
              owner = "tree-sitter";
              repo = "tree-sitter";
              tag = "v0.26.8";
              hash = "sha256-fcFEfoALrbpBD6rWogxJ7FNVlvDQgswoX9ylRgko+8Q=";
              fetchSubmodules = true;
            };
            buildPhase = "make libtree-sitter.a libtree-sitter.so";
            installPhase = ''
              mkdir -p $out/lib $out/include/tree_sitter $out/lib/pkgconfig
              cp libtree-sitter.so libtree-sitter.a $out/lib/
              ln -s libtree-sitter.so $out/lib/libtree-sitter.so.0
              ln -s libtree-sitter.so $out/lib/libtree-sitter.so.0.26
              cp lib/include/tree_sitter/api.h $out/include/tree_sitter/
              cat > $out/lib/pkgconfig/tree-sitter.pc <<EOF
              prefix=$out
              libdir=''${prefix}/lib
              includedir=''${prefix}/include

              Name: tree-sitter
              Description: incremental parsing library
              Version: 0.26.8
              Libs: -L''${libdir} -ltree-sitter
              Cflags: -I''${includedir}
              EOF
            '';
            passthru = prev.tree-sitter.passthru or {};
          }
        else prev.tree-sitter;

      # NOTE: nlua0 codegen lib is armv7, run generator with target luajit via binfmt
      neovim-unwrapped =
        if prev.stdenv.hostPlatform.isAarch32
        then prev.neovim-unwrapped.overrideAttrs (old: {
          cmakeFlags = (old.cmakeFlags or []) ++ [
            (lib.cmakeFeature "LUA_GEN_PRG" "${prev.luajit}/bin/luajit")
            # NOTE: x86 luajit produces 64-bit bytecode, armv7 nvim needs 32-bit; ship plain lua
            (lib.cmakeBool "COMPILE_LUA" false)
          ];
        })
        else prev.neovim-unwrapped;

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
            mesonFlags =
              (old.mesonFlags or [])
              ++ [
                "--cross-file=${prev.writeText "matplotlib-host-python.ini" ''
                  [binaries]
                  python = '${psuper.python}/bin/python3.13'
                ''}"
              ];
            # NOTE: pybind11-config runs x86_64 python and injects its include dir
            postPatch =
              (old.postPatch or "")
              + ''
                substituteInPlace meson.build --replace-fail \
                  "pybind11_dep = dependency('pybind11', version: '>=2.13.2')" \
                  "pybind11_dep = dependency('pybind11', version: '>=2.13.2', method: 'pkg-config')"
              '';
            preConfigure =
              (old.preConfigure or "")
              + ''
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
    filter = "*bananapi-m2-zero*";
    overlays = [
      {
        name = "uart3-enable";
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

  # NOTE: RTC_DRV_SUN6I missing from nixpkgs armv7 kernel config
  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_latest.override {
    structuredExtraConfig = with lib.kernel; {
      RTC_DRV_SUN6I = yes;
      # NOTE: 7.x pwrseq_simple via reset-gpio module fails on this board,
      RESET_GPIO = no;
    };
  });

  # NOTE: only AP6212 wifi firmware, not all of linux-firmware
  hardware.enableRedistributableFirmware = lib.mkForce false;
  hardware.firmware = [
    (pkgs.runCommand "firmware-brcm43430" {} ''
      mkdir -p $out/lib/firmware/brcm
      src=${pkgs.linux-firmware}/lib/firmware/brcm
      cp $src/brcmfmac43430-sdio.bin* $out/lib/firmware/brcm/
      cp $src/brcmfmac43430-sdio.clm_blob* $out/lib/firmware/brcm/
      for f in $src/brcmfmac43430-sdio.AP6212.txt*; do
        cp "$f" "$out/lib/firmware/brcm/brcmfmac43430-sdio.txt''${f##*.AP6212.txt}"
      done
    '')
    pkgs.wireless-regdb
  ];

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
