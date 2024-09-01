# Shoji-nix 

### Bundle and encrypt your SSH Keys

This flake provides a way to encrypt and bundle your SSH keys and SSH config so you can save them along your GitOps files in a public repository!
The result is one readable yaml file with encrypted fields of your choice.

<img src="https://github.com/AdoPi/shoji-nix/assets/5956940/84de5a8b-04fe-42f3-ba52-b5f74b2c1ce4" width="250" height="250">

Shoji-Nix is a Nix flake designed to manage and securely store your SSH keys. With Shoji-Nix, you can bundle your SSH configuration and .ssh folder into a YAML file, which you can then be encrypted and saved in your repository.

Shoji-Nix uses the robust encryption tools SOPS and AGE, allowing you to encrypt not just your private SSH key, but also the username, IP address, hostname of your SSH configuration. This feature provides an added layer of security and helps maintain your anonymity.

Warning: This is a POC, it is very experimental!!! Use at your own risk! Please backup your files before using it.

# Quick start

You only need two commands!

The first one is for bundling and encrypting your .ssh folder into a yaml file.

```
    $ nix run github:AdoPi/shoji-nix#shoji-init -- -k ssh -c ~/.ssh/config -o ssh.yaml -g age.txt
```

The result is an encrypted `ssh.yaml` which contains your .ssh keys and ssh config! 
It has been encrypted with the public key contained in `age.txt`, thanks to the -g option which generates an age key file for you.

You can now commit your encrypted ssh.yaml publicly!

To decrypt it, just use this second command:

```
  $ nix run github:AdoPi/shoji-nix#shoji-run -- -k ~/.ssh -o ~/.ssh/config -p age.txt -y ssh.yaml
```

Warnings: 
* Don't lose your age key! It is mandatory for decrypting your yaml bundled by Shoji.
* Shoji is very experimental, please backup your files before using it!

# Guide

This section contains more information and examples about shoji-nix

## Init
Create a yaml file with shoji, encrypts it using age and sops.

```
nix run github:AdoPi/shoji-nix#shoji-init -- -k ~/.ssh -c ~/.ssh/config -o ssh.yaml -a $(cat ~/.sops/age/keys.txt | grep public | grep -oP "public key: \K(.*)")
```

You can also define your own encryption-regex

```
nix run github:AdoPi/shoji-nix#shoji-init -- -k ~/.ssh -c ~/.ssh/config -o ssh.yaml -a $(cat ~/.sops/age/keys.txt | grep public | grep -oP "public key: \K(.*)") -r '(name|identity)'
```

If you don't want to encrypt your file, you can run shoji-init without an age public key file.
Then you can encrypt it yourself with sops (and age) using your own `.sops.yaml` file.

```
nix run github:AdoPi/shoji-nix#shoji-init -- -k ~/.ssh -c ~/.ssh/config -o ssh.yaml
# Resulting ssh.yaml is not encrypted
```

## Decrypting and installing your ssh folder

```
  $ nix run github:AdoPi/shoji-nix#shoji-run -- -k ~/.ssh -o ~/.ssh/config -p age.txt -y ssh.yaml
```
TODO DOC


## NixOs users

### Using shoji in your configuration.nix

Once you have run #shoji-init, you can use shoji-nix as a module to laod and decrypt your bundled yaml file.
This module provides a way to decrypt and unbundle your SSH keys directly from your Nix configuration files.

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
### Examples
For more informations, you can find a simple example in the `examples` folder.

