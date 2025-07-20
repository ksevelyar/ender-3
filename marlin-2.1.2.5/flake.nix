{
  description = "PlatformIO dev shell with runtime dependencies fixed";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/b58df7fc9d5f02c269091f2b0b81a6e06fc859bb";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            platformio
            python312
            zstd
            zlib
            gcc
            gdb
            gnumake
            udev
            libusb1
            openssl
            ncurses
          ];

          shellHook = ''
            export PLATFORMIO_CORE_DIR=$PWD/.platformio
            export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath [
              pkgs.zstd
              pkgs.stdenv.cc.cc.lib
            ]}:$LD_LIBRARY_PATH
            export PYTHONPATH=${pkgs.platformio}/lib/python3.12/site-packages:$PYTHONPATH

            # Initialize PlatformIO environment if needed
            if [ ! -d "$PLATFORMIO_CORE_DIR/penv" ]; then
              echo "Initializing PlatformIO environment..."
              platformio platform install https://github.com/p3p/pio-nxplpc-arduino-lpc176x/archive/0.1.3.zip
            fi
          '';
        };
      }
    );
}
