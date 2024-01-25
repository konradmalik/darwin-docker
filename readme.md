# Docker module for nix-darwin

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

Then rebuild your config, restart your shell, and run:

```bash
$ docker info
```

It should connect and print relevant info.

See the module code for more options.

Tip: if you have a NixOS config for docker, you should be able to do something like this:

-   in linux.nix

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

-   in darwin.nix:

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

-   why? because if you're already using nix-darwin, then this VM will be very lightweight in terms of disk space and very fast to start
-   this builds on top of `nix-builder` module and `darwin-builder` VM
-   it runs as a daemon in the background
-   docker is exposed on `tcp://127.0.0.1:2375` on the host system
-   `DOCKER_HOST` env variable is set to the above address
-   you will most probably need to enable `nix-builder` as well to actually build this VM, at least the first time
-   configuration/customization can be easilty done via `virtualisation.docker.config` - this gets directly passed to the underlying NixOS VM config as a module
-   ssh access directly to the machine should be possible with: `ssh -i /var/lib/darwin-docker/keys/builder_ed25519 -- builder@darwin-docker`
