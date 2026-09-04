# SPDX-License-Identifier: MIT
{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:
rustPlatform.buildRustPackage rec {
  pname = "merman";
  version = "0.8.0-alpha.5";

  src = fetchFromGitHub {
    owner = "Latias94";
    repo = "merman";
    rev = "v${version}";
    hash = "sha256-DeFW51g5d98hcp1qa0sNXvRoOhugUcWs7b6HEHEpa9E=";
  };

  cargoHash = "sha256-FKTeFbo9YtHOSPeb1h/bh2UN3AwMZh9mPqADbsQC32c=";

  # merman-lsp: mermaid language server; merman-cli: headless
  # mmdc-compatible renderer (SVG/PNG without a browser).
  # The merman-lsp binary is gated behind the crate's non-default
  # "stdio" feature (required-features on the [[bin]] target); without
  # it cargo skips the binary silently.
  cargoBuildFlags = [
    "--package"
    "merman-lsp"
    "--package"
    "merman-cli"
    "--features"
    "merman-lsp/stdio"
  ];

  # The workspace test suite wants the full upstream SVG fixture corpus;
  # the built binaries are exercised by the smoke check instead
  # (rendering, the flag set consumers pass, detection, LSP handshake).
  doCheck = false;

  meta = {
    description = "Headless Rust mermaid implementation: language server and renderer";
    homepage = "https://github.com/Latias94/merman";
    license = with lib.licenses; [
      mit
      asl20
    ];
    mainProgram = "merman-cli";
  };
}
