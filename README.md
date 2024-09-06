# Shoji-nix 

### Bundle and encrypt your SSH Keys

This flake provides a way to encrypt and bundle your SSH keys and SSH config in a readable format! 

[Quick Start](https://github.com/AdoPi/shoji-nix?tab=readme-ov-file#quick-start)

The result is one readable yaml file with encrypted fields of your choice. You can save it along your GitOps files in a public repository.

<img src="https://github.com/AdoPi/shoji-nix/assets/5956940/84de5a8b-04fe-42f3-ba52-b5f74b2c1ce4" width="250" height="250">

Shoji-Nix is a Nix flake designed to manage and securely store your SSH keys. With Shoji-Nix, you can bundle your SSH configuration and .ssh folder into a YAML file which can then be encrypted and saved in your repository.

Shoji-Nix uses the robust encryption tools SOPS and AGE, allowing you to encrypt not just your private SSH key, but also the username, IP address, hostname of your SSH configuration. This feature provides an added layer of security and helps maintain your anonymity.

⚠️ Shoji is very experimental, use it at your own risk! Please backup your files before using it!

# Quick start

You only need two commands!

The first one is for bundling and encrypting your .ssh folder into a yaml file.

```
$ nix run 'github:AdoPi/shoji-nix#shoji-init' -- -o ssh.yaml -g age.txt
```

The result is an encrypted `ssh.yaml` which contains your .ssh keys and ssh config! 
It has been encrypted with the public key contained in `age.txt` generated for you thanks to the -g option.

You can now commit your encrypted ssh.yaml publicly!

To decrypt it, just use this second command:

```
$ nix run 'github:AdoPi/shoji-nix#shoji-run' -- -o ~/.ssh/config -p age.txt -y ssh.yaml
```

⚠️ Don't lose your age key! It is mandatory for decrypting your yaml bundled by Shoji.

⚠️ Please backup your files before using it!

# What you get with Shoji-nix

If you have a `~/.ssh/config` which contains the following:

```
Host example
	Hostname example.com
	User example-user
	Port 2222
	IdentityFile ~/.ssh/example.key

Host shoji
	Hostname shoji-example.com
	User example-shoji
	Port 2222
	IdentityFile ~/.ssh/shoji-example.key

```

Shoji-nix will bundle and encrypt all keys inside one Yaml file, the result is there:

```
hosts:
    - name: example
      user: example-user
      port: "2222"
      identity: ENC[AES256_GCM,data:ENCRYPTED_REMOVED_FOR_CLARITY==,type:str]
      hostname: ENC[AES256_GCM,data:BkMMk0ClkBtB2DY=,iv:weOotqhEEwgNAOrJRXt06uNny3UT0mFYYSJKlyj+Mzk=,tag:lam8Lu5Z1hX5K8xZm6zb4g==,type:str]
      data: ""
    - name: shoji
      user: example-shoji
      port: "2211"
      identity: ENC[AES256_GCM,data:ENCRYPTED_REMOVED_FOR_CLARITY==,type:str]
      hostname: ENC[AES256_GCM,data:7zB2aypWn3K8eGR6V/AIizE=,iv:/rJ0zOjlospgl6Fd+OR7bqaUOmiGLuHLdsRm/2IKyg4=,tag:iVFTR/RdwZJKk0dSARnePQ==,type:str]
      data: ""
sops:
    ...
    Info about Sops and Age here
    ...
    encrypted_regex: hostname|identity
    version: 3.8.1

```

You can then decrypt and unbundle your yaml file whenever you want, you will get an ssh folder again.


```
$ ls -l ~/.ssh/

-rw-r--r-- 1 shoji-user users  316 Sep  1 10:43 config
-rw------- 1 shoji-user users  411 Sep  1 10:43 example-shoji-shoji-a6f48472.key
-rw------- 1 shoji-user users  411 Sep  1 10:43 example-user-example-3828fa55.key
```

The ~/.ssh/config will be similar to this one:

```
$ cat ~/.ssh/config
Host example
	User example-user
	IdentityFile /home/shoji-user/.ssh/example-user-example-3828fa55.key
	Hostname example.com
	Port 2222
Host shoji
	User example-shoji
	IdentityFile /home/shoji-user/.ssh/example-shoji-shoji-a6f48472.key
	Hostname shoji-example.com
	Port 2211
```

Some options are availables, for example you can customize the path of ssh files, choose which fields to encrypt, etc... You can use `--help` for more information.


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

:construction: This section of the documentation is in WIP.

If you are not a NixOs user if you don't want to use the Shoji-nix module, you can decrypt your .ssh keys with the #shoji-run command.

```
  $ nix run github:AdoPi/shoji-nix#shoji-run -- -k ~/.ssh -o ~/.ssh/config -p age.txt -y ssh.yaml
```



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

