# Docker module for nix-darwin

## Before enable

You may need to enable to `linux-builder` without this addon first (`nix.linux-builder.enable = true`).
This is because you need some machine to build linux configuration on darwin.

## Usage

Import the module to your configuration, then enable with:

```nix
# just an example
{ inputs, ... }:
{
  imports = [
    inputs.darwin-docker.darwinModules.docker
  ];

  virtualisation.docker = {
    enable = true;
  };
}
```

Then rebuild your config, make sure `DOCKER_HOST` is set. If not set it manually:

```bash
export DOCKER_HOST="tcp://127.0.0.1:2375"
```

then run:

```bash
$ docker info
```

It should connect and print relevant info.

See the module code for more options.

Tip: if you have a NixOS config for docker, you should be able to do something like this:

- in linux.nix

```nix
{
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      flags = [ "--all" ];
      dates = "weekly";
    };
  };
}
```

- in darwin.nix:

```nix
{ pkgs, inputs, ... }:
{
  imports = [
    inputs.darwin-docker.darwinModules.docker
  ];

  virtualisation.docker = {
    enable = true;
    config = import ./linux.nix;
  };
}
```

## Notes

- why? because if you're already using nix-darwin, then this VM will be very lightweight in terms of disk space and very fast to start
- this builds on top of `nix-builder` module and `darwin-builder` VM
- it runs as a daemon in the background
- docker is exposed on `tcp://127.0.0.1:2375` on the host system
- `DOCKER_HOST` env variable is set to the above address
- configuration/customization can be easilty done via `virtualisation.docker.config` - this gets directly passed to the underlying NixOS VM config as a module
- ssh access directly to the machine should be possible with: `sudo ssh linux-builder`
