# SPDX-License-Identifier: MIT
{ ... }:
{
  config,
  inputs,
  lib,
  ...
}:
{

  debug = false;
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  caisson = {
    configInfo.configName = "merman";
    libOverlays.exported = libOverlays: {
      inherit (libOverlays) default;
    };

    nixpkgs = {
      overlays.all = {
        packages = lib.caisson.nixpkgs.mkPackagesOverlay ../../../pkgs;
      };
      overlays.export.enabled = true;
      overlays.exported = overlays: { inherit (overlays) packages; };
      pkgSets.pkgs = {
        pkgFunction = import inputs.nixpkgs;
        overlayImports = overlays: [ overlays.packages ];
      };
      packages.export.enabled = true;
    };
  };

  # `nix run github:clhodapp/merman` should reach the renderer, which is
  # the binary anyone arrives here for.
  perSystem =
    { config, ... }:
    {
      packages.default = config.packages.merman;
    };

  partitionedAttrs.checks = "checks";
  partitionedAttrs.formatter = "formatter";

  partitions.formatter = {
    extraInputs = lib.caisson-core.partitionExtraInputs ../../../tests/dependencies;
    module =
      { inputs, ... }:
      {
        imports = [ inputs.treefmt-nix.flakeModule ];
        perSystem.treefmt.programs.nixfmt.enable = true;
      };
  };

  partitions.checks = {
    extraInputs = lib.caisson-core.partitionExtraInputs ../../../tests/dependencies;
    module =
      { inputs, self, ... }:
      {
        imports = [ inputs.treefmt-nix.flakeModule ];
        perSystem =
          { pkgs, system, ... }:
          let
            merman = self.packages.${system}.merman;
          in
          {
            checks = {
              # Exercise the built binaries over the interfaces consumers
              # actually use. Upstream is pre-1.0 and has twice changed
              # what ships: a bump silently dropped a binary (cargo
              # required-features gating) and moved the CLI surface
              # behind a subcommand. Building alone would not have caught
              # either.
              smoke = pkgs.runCommand "merman-smoke" { } ''
                # The mmdc interface: source on stdin, SVG to a file.
                printf 'graph TD\n  A-->B\n' \
                  | ${merman}/bin/merman-cli mmdc -i - -o diagram.svg
                grep -q '<svg' diagram.svg

                # The full flag set callers pass, with htmlLabels off so
                # labels stay native <text> (librsvg drops foreignObject).
                printf '{"htmlLabels": false, "flowchart": {"htmlLabels": false}}' \
                  > config.json
                printf 'graph TD\n  A-->|label| B\n' \
                  | ${merman}/bin/merman-cli mmdc -i - -o flags.svg -q \
                      -c config.json -t dark -b transparent
                grep -q '<text' flags.svg
                if grep -q foreignObject flags.svg; then exit 1; fi

                # The detector: recognizes mermaid source, refuses prose.
                printf 'sequenceDiagram\n  A->>B: hi\n' \
                  | ${merman}/bin/merman-cli detect
                if printf 'plain prose\n' \
                  | ${merman}/bin/merman-cli detect 2>/dev/null; then
                  exit 1
                fi

                # The LSP transport: an initialize request over stdio
                # must come back with a capability set.
                body='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"capabilities":{}}}'
                printf 'Content-Length: %d\r\n\r\n%s' "''${#body}" "$body" \
                  | ${merman}/bin/merman-lsp > response 2> /dev/null
                grep -q '"capabilities"' response

                touch $out
              '';
            };
            treefmt.programs.nixfmt.enable = true;
          };
      };
  };

}
