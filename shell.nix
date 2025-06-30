let
  pkgs = import <nixpkgs> {};
in
  pkgs.pkgsCross.riscv32.mkShell {
    nativeBuildInputs = with pkgs; [
      gcc
      llvmPackages_12.clang
      ghc
      busybox
      iverilog
      gtkwave
      cargo
      rustup
      rustc
    ];
  }
