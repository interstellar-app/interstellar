# Todo: Add support for Android development and builds
{
description = "Flutter development environment for Interstellar";
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  flake-utils.url = "github:numtide/flake-utils";
};
outputs = { self, nixpkgs, flake-utils }:
  flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          # android_sdk.accept_license = true;
          # allowUnfree = true;
        };
      };
      # androidSdk = pkgs.androidenv.androidPkgs.androidsdk;
    in
    {
      devShell =
        with pkgs; mkShell {
          nativeBuildInputs = with pkgs; [
            pkg-config
          ];
          # ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
          buildInputs = [
            flutter350
            mpv-unwrapped
            alsa-lib
            libglvnd
            wayland
            # androidSdk
            # jdk25
          ];
        };
    });
}
