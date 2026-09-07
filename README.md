# merman

Nix packaging of [merman](https://github.com/Latias94/merman), a
headless Rust implementation of mermaid. It ships two binaries:
`merman-cli`, a renderer that takes mermaid source and writes SVG or
PNG without a browser, and `merman-lsp`, a mermaid language server.

merman is not in nixpkgs, so this flake packages it and exports the
result as an overlay.

## Use it

```sh
nix run github:clhodapp/merman -- mmdc -i diagram.mmd -o diagram.svg
```

As a flake input:

```nix
{
  inputs.merman.url = "github:clhodapp/merman";

  # the package:
  #   inputs.merman.packages.${system}.merman
  # or through the overlay, landing at pkgs.merman.merman:
  #   nixpkgs.overlays = [ inputs.merman.overlays.packages ];
}
```

`merman-cli` implements the `mmdc` interface that mermaid-cli defines,
so it substitutes for `mmdc` in tooling that shells out to it, without
pulling in a headless browser.

## Development

`nix flake check` builds the package and runs a smoke check that
exercises the built binaries over the interfaces callers use: the `mmdc`
rendering path, the flag set that keeps labels as native `<text>`,
source detection, and an LSP `initialize` handshake over stdio.

That check earns its place. Upstream is pre-1.0, and the 0.8.0-alpha.5
bump both silently dropped a binary (cargo `required-features` gating on
the `[[bin]]` target) and moved the CLI surface behind a subcommand.
Building the package alone would have caught neither.

`nix fmt` formats.

## Binary cache

What `main` builds is pushed to the `clhodapp` cachix cache, signed with
its key, so a consumer at the same pins substitutes the compiled binary
instead of building it. That cache skips paths its upstreams already
hold, so using it means using them too:

| Substituter | Public key |
|---|---|
| `https://clhodapp.cachix.org` | `clhodapp.cachix.org-1:EW/0conxH0OQyo0o4ub/grdkFspholmQMSnQyj0vrZI=` |
| `https://nix-community.cachix.org` | `nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=` |
| `https://numtide.cachix.org` | `numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE=` |

The flake's `nixConfig` declares all three, so a direct `nix build` or
`nix flake check` here uses them once accepted: answer Nix's prompt, or
pass `--accept-flake-config`. A flake that consumes this one
as an input must add them to its own `extra-substituters` and
`extra-trusted-public-keys`; Nix does not carry an input's settings
into the consumer.

## License

The packaging here is MIT, see [`LICENSE`](LICENSE). merman itself is
dual MIT and Apache-2.0, upstream.
