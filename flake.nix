# SPDX-License-Identifier: MIT
{

  description = "Nix packaging of merman, a headless mermaid language server and renderer";

  inputs = {
    caisson.url = "github:nix-caisson/caisson";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs@{ caisson, ... }:
    let
      lib = caisson.lib.caisson-core.mkLib {
        inherit inputs;

        projects = {
          inherit caisson;
        };

        libOverlays = mkLibOverlay: {
          default = mkLibOverlay ./lib-overlays/default;
        };
      };
    in
    lib.caisson.mkFlake {
      name = "merman";
      configModule = lib.caisson.mkFlakeModule ./configs/flake-parts/default;
    };

}
