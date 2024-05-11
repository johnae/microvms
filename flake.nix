{
  description = "NixOS in MicroVMs";

  inputs.microvm.url = "github:astro/microvm.nix";
  inputs.microvm.inputs.nixpkgs.follows = "nixpkgs";

  outputs = {
    self,
    nixpkgs,
    microvm,
  }: let
    system = "x86_64-linux";
  in {
    defaultPackage.${system} = self.packages.${system}.my-microvm;

    packages.${system}.my-microvm = let
      inherit (self.nixosConfigurations.my-microvm) config;
      # quickly build with another hypervisor if this MicroVM is built as a package
      hypervisor = "cloud-hypervisor";
    in
      config.microvm.runner.${hypervisor};

    nixosConfigurations.my-microvm = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        microvm.nixosModules.microvm
        ({pkgs, ...}: {
          networking.hostName = "my-microvm";
          networking.firewall.allowedUDPPorts = [67];
          systemd.network.enable = true;
          systemd.network.networks."10-lan" = {
            matchConfig.Name = "enp*";
            networkConfig.DHCP = "ipv4";
            # address = [
            #   "10.100.0.2/27"
            # ];
            # routes = [
            #   {routeConfig.Gateway = "10.100.0.1";}
            # ];
          };
          services.tailscale.enable = true;
          users.users.root.hashedPassword = "$6$d6erGtUBlhIR/WaN$N5TwjLxlY1nD.neCyd5h7VGO3jqXUfQg6ZWbuc9ByLQvL3LT/15hX992bLAdP46enllfF2LiBcx4IvObMlp1p/";
          users.users.root.openssh.authorizedKeys.keys = [
            "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCyjMuNOFrZBi7CrTyu71X+aRKyzvTmwCEkomhB0dEhENiQ3PTGVVWBi1Ta9E9fqbqTW0HmNL5pjGV+BU8j9mSi6VxLzJVUweuwQuvqgAi0chAJVPe0FSzft9M7mJoEq5DajuSiL7dSjXpqNFDk/WCDUBE9pELw+TXvxyQpFO9KZwiYCCNRQY6dCjrPJxGwG+JzX6l900GFrgOXQ3KYGk8vzep2Qp+iuH1yTgEowUICkb/9CmZhHQXSvq2gAtoOsGTd9DTyLOeVwZFJkTL/QW0AJNRszckGtYdA3ftCUNsTLSP/VqYN9EjxcMHQe4PGjkK7VLb59DQJFyRQqvPXiUyxNloHcu/sDuiKHIk/0qDLHlVn2xc5zkvzSqoQxoXx+P4dDbje1KHLY8E96gLe2Csu0ti+qsM5KEvgYgwWwm2g3IBlaWwgAtC0UWEzIuBPrAgPd5vi+V50ITIaIk6KIV7JPOubLUXaLS5KW77pWyi9PqAGOXj+DgTWoB3QeeZh7CGhPL5fAecYN7Pw734cULZpnw10Bi/jp4Nlq1AJDk8BwLUJbzZ8aexwMf78syjkHJBBrTOAxADUE02nWBQd0w4K5tl/a3UnBYWGyX8TD44046Swl/RY/69PxFvYcVRuF4eARI6OWojs1uhoR9WkO8eGgEsuxxECwNpWxR5gjKcgJQ=="
            "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIJY3QSBIiRKN8/B3nHgCBDp;auQBOftphOeuF2TaBHGQSAAAABHNzaDo="
            "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIAwJWtQ5ZU9U0szWzJ+/GH2uvXZ15u9lL0RdcHdsXM0VAAAABHNzaDo="
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK+trOinD68RD1efI6p05HeaNA0SjzeRnUvpf22+jsq+"
          ];
          environment.systemPackages = with pkgs; [
            zellij
            git
            helix
          ];
          users.users.john = {
            uid = 1337;
            shell = pkgs.nushell;
            isNormalUser = true;
            hashedPassword = "$6$d6erGtUBlhIR/WaN$N5TwjLxlY1nD.neCyd5h7VGO3jqXUfQg6ZWbuc9ByLQvL3LT/15hX992bLAdP46enllfF2LiBcx4IvObMlp1p/";
            extraGroups = ["wheel" "docker" "video" "audio" "kvm" "libvirtd"];
          };
          services.openssh = {
            enable = true;
            settings.PermitRootLogin = "yes";
          };
          microvm = {
            volumes = [
              {
                mountPoint = "/var";
                image = "var.img";
                size = 256;
              }
            ];
            shares = [
              {
                # use "virtiofs" for MicroVMs that are started by systemd
                proto = "virtiofs";
                tag = "ro-store";
                # a host's /nix/store will be picked up so that the
                # size of the /dev/vda can be reduced.
                source = "/nix/store";
                mountPoint = "/nix/.ro-store";
              }
            ];
            socket = "control.socket";
            hypervisor = "cloud-hypervisor";
            vcpu = 4;
            mem = 16384;
            interfaces = [
              {
                type = "tap";
                id = "vm-1";
                mac = "02:00:00:00:00:01";
              }
            ];
          };
        })
      ];
    };
  };
}
