# Shoji-nix 

### SSH Key Management Module for Nix

This module is a way to save SSH keys securely in your Nix configuration.

Shoji-Nix is a Nix module designed to manage and securely store your SSH keys. With Shoji-Nix, you can transform your SSH configuration and .ssh folder into a YAML file, which you can then encrypt and save in your Nix configuration.

Shoji-Nix uses the robust encryption tools SOPS and AGE, allowing you to encrypt not just your private SSH key, but also the username, IP address, and hostname of your SSH configuration. This feature provides an added layer of security and helps maintain your anonymity.


# Init
Create a yaml file with shoji, encrypts it using age and sops.

```
nix run .#shoji-init -- -k ~/.ssh -c ~/.ssh/config -o ssh.yaml -a $(cat ~/.sops/age/keys.txt | grep public | grep -oP "public key: \K(.*)")
```

You can also define your own encryption-regex

```
nix run .#shoji-init -- -k ~/.ssh -c ~/.ssh/config -o ssh3.yaml -a $(cat ~/.sops/age/keys.txt | grep public | grep -oP "public key: \K(.*)") -r '(name|identity)'
```

If you don't want to encrypt your file, you can run shoji-init without an age public key file.
Then you can encrypt it with sops (and age) using your own `.sops.yaml` file.

```
nix run .#shoji-init -- -k ~/.ssh -c ~/.ssh/config -o ssh.yaml
```

## Usage in your configuration.nix

Include shoji-nix as a module in your nix code.

```
input = {
  shoji-nix.url = "github:AdoPi/shoji-nix";
};
```

```
modules = [
  shoji-nix.nixosModules.shoji
]
```

Then you can define your own shoji configuration.

```
{config, ...} :
{
  shoji.enable = true;
  shoji.ssh-folder = "/root/.ssh";
  shoji.owner = "root";
  shoji.group = "users";
  shoji.age-keyfile = "/root/.sops/me.key";
  shoji.ssh-config = "/root/.ssh/config";
  shoji.yaml-config =  ./ssh.yaml;
}
```
## Examples
For more informations, you can find a simple example in the `examples` folder.
