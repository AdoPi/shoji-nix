# sudo nixos-rebuild switch --flake .#osaka
# sudo nix-env --delete-generations old --profile /nix/var/nix/profiles/system
#
#
sudo nixos-rebuild switch --flake .#myHome --show-trace
