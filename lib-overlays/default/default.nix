# SPDX-License-Identifier: MIT
{ ... }:
{

  overlay = final: prev: {
    merman-nix = prev.merman-nix or { };
  };

}
