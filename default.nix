{ nixpkgs ? (import <nixpkgs> { }).fetchgit {
  url = "https://github.com/NixOS/nixpkgs.git";
  rev = "ce9f1aaa39ee2a5b76a9c9580c859a74de65ead5";
  sha256 = "1s2b9rvpyamiagvpl5cggdb2nmx4f7lpylipd397wz8f0wngygpi";
}, overlayUrl ? "git@gitlab.intr:_ci/nixpkgs.git", overlayRef ? "master" }:

with import nixpkgs {
  overlays = [
    (import (builtins.fetchGit { url = overlayUrl; ref = overlayRef; }))
  ];
};

let
  inherit (lib) flattenSet dockerRunCmd;
  inherit (import ./common.nix { })
    extraCommands Env contents rootfs dockerArgHints redis;
in pkgs.dockerTools.buildLayeredImage rec {
  inherit contents extraCommands;
  name = "docker-registry.intr/webservices/redis";
  tag = "latest";
  config = {
    inherit Env;
    Entrypoint = [ "${redis}/bin/redis-server"
                   "--unixsocket" "/home/redis.socket"
                   "--unixsocketperm" "775"
                   "--daemonize" "no"
                   "--stop-writes-on-bgsave-error" "no"
                   "--rdbcompression" "yes"
                   "--maxmemory" "50M"
                   "--maxmemory-policy" "allkeys-lru"];
    Labels = flattenSet rec {
      ru.majordomo.docker.arg-hints-json = builtins.toJSON dockerArgHints;
      ru.majordomo.docker.cmd =
        dockerRunCmd dockerArgHints "${name}:${tag}";
    };
  };
}
