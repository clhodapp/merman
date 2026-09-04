# SPDX-License-Identifier: MIT
{ ... }:
{

  overlay = final: prev: {
    merman = prev.merman or { };
  };

}
