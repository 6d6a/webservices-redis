{ nixpkgs ? (import <nixpkgs> { }).fetchgit {
  url = "https://github.com/NixOS/nixpkgs.git";
  rev = "ce9f1aaa39ee2a5b76a9c9580c859a74de65ead5";
  sha256 = "1s2b9rvpyamiagvpl5cggdb2nmx4f7lpylipd397wz8f0wngygpi";
}, overlayUrl ? "git@gitlab.intr:_ci/nixpkgs.git", overlayRef ? "master" }:

with import nixpkgs {
  overlays = [
    (import (builtins.fetchGit { url = overlayUrl; ref = overlayRef; }))
  ];
  config = { allowUnfree = true; };
};

let
  inherit (lib) mkRootfs;
  inherit (lib.attrsets) collect isDerivation;

in rec {
  inherit redis;

  dockerArgHints = {
    read_only = true;
    user = "$UNIX_ACCOUNT_UID";
    environment = {
      UNIX_ACCOUNT_HOMEDIR = "$UNIX_ACCOUNT_HOMEDIR";
    };
    volumes = [
      (rec { source = "$UNIX_ACCOUNT_HOMEDIR"; target = "/home"; type = "bind"; })
      ({ target = "/run"; type = "tmpfs"; })
    ];
  };

  contents = [
    tzdata
    locale
    bashInteractive
    coreutils
    findutils
    redis
  ];

  Env = [
    "TZ=Europe/Moscow"
    "TZDIR=${tzdata}/share/zoneinfo"
    "LOCALE_ARCHIVE_2_27=${locale}/lib/locale/locale-archive"
    "LOCALE_ARCHIVE=${locale}/lib/locale/locale-archive"
    "LC_ALL=en_US.UTF-8"
  ];

  extraCommands = ''
    set -xe
    ls
    mkdir -p etc
    mkdir -p usr/local
    mkdir -p opt
    mkdir root
    ln -s /bin usr/bin
    ln -s /bin usr/sbin
    ln -s /bin usr/local/bin
    mkdir tmp
    chmod 1777 tmp
  '';

}
