{
  inputs.nixpkgs.follows = "hydra/nixpkgs";
  inputs.hydra.url = "github:regnat/hydra/nix-ca";

  outputs = { self, nixpkgs, hydra }: {

    nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        hydra.nixosModules.hydraTest
        hydra.nixosModules.hydraProxy
        {
          networking.firewall.allowedTCPPorts = [ 80 ];
          networking.hostName = "hydra";

          services.hydra-dev.useSubstitutes = true;

          nix.extraOptions = ''
                experimental-features = nix-command flakes ca-derivations ca-references
          '';
        }
        {
          fileSystems."/" = {
            device = "/dev/disk/by-label/nixos";
            fsType = "ext4";
            autoResize = true;
          };
          boot.growPartition = true;
          boot.kernelParams = [ "console=ttyS0" ];
          boot.loader.grub.device = "/dev/vda";
          boot.loader.timeout = 0;

          users.extraUsers.root.password = "";
          systemd.services.hydra-server.postStart = ''
            hydra-create-user root --email-address 'alice@example.org' --password foobar --role admin
          '';
        }
        (nixpkgs.outPath + "/nixos/modules/profiles/qemu-guest.nix")
        ({ config, pkgs, lib, ... }: {
          system.build.qcow2 = import (pkgs.path + "/nixos/lib/make-disk-image.nix") {
          inherit lib config pkgs;
            diskSize = 8192;
            format = "qcow2";
            configFile = pkgs.writeText "configuration.nix"
            '' { imports = [ <./machine-config.nix> ]; } '';
          };
        })
      ];
    };
  };
}

