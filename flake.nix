{
  description = "Manage SSH keys with Nix";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.nixpkgs-stable.url = "github:NixOS/nixpkgs/release-23.11";
  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable
  }: let
    systems = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
      "aarch64-linux"
    ];

    forAllSystems = f: builtins.listToAttrs (map (system: { name = system; value = f system; }) systems);
    genAttrs = names: f: builtins.listToAttrs (map (name: { inherit name; value = f name; }) names);

    packagesForSystem = system: let
      pkgs = nixpkgs.legacyPackages.${system};

      shoji = pkgs.buildGoModule rec {
  	pname = "shoji";
	name = "shoji";
	version = "0.0.1";

        src = pkgs.fetchFromGitHub {
          owner = "AdoPi";
          repo = "${pname}";
          rev = "v${version}";
          hash = "sha256-jGozqQYY/FH+tMPJ+3xxjuZ8DPjb01F0cHKLnrsebls=";
        };
	vendorHash = "sha256-uvpMGk0MbjR7kGRL2K1uP1vH30TAuz/ULEjObW6udyA=";
      };

      shojiInitAgeScript = pkgs.writeShellScriptBin "shoji-init" ''
        #!/usr/bin/env bash
        keys_directory="~/.ssh"
        ssh_config="~/.ssh/config"
        output="ssh.yaml"
	age_public_keys=""
	encrypted_regex="'(hostname|identity|name)'"

        # Parsing options
        while (( "$#" )); do
          case "$1" in
            -o|--output)
              if [ -n "$2" ] && [ $${2:0:1} != "-" ]; then
                output=$2
                shift 2
              fi
              ;;
            -k|--keys-directory)
              if [ -n "$2" ] && [ $${2:0:1} != "-" ]; then
                keys_directory=$2
                shift 2
              fi
              ;;
            -c|--ssh-config)
              if [ -n "$2" ] && [ $${2:0:1} != "-" ]; then
                ssh_config=$2
                shift 2
              fi
              ;;
            -a|--age-public-keys)
              if [ -n "$2" ] && [ $${2:0:1} != "-" ]; then
                age_public_keys=$2
                shift 2
              fi
              ;;
            -r|--regex)
              if [ -n "$2" ] && [ $${2:0:1} != "-" ]; then
                encrypted_regex=$2
                shift 2
              fi
              ;;
            -h|--help)
              echo "-k, --keys-directory:"
              echo "    Specifies the location of the directory that contains the ssh keys, usually \$HOME/.ssh."
              echo ""
              echo "-o, --output:"
              echo "    Path to the generated yaml file."
              echo ""
              echo "-c, --ssh-config:"
              echo "    Specifies the location of the ssh config file, usually \$HOME/.ssh/config."
              echo ""
              echo "-a, --age-public-key:"
              echo "    Public age keys with which to encrypt the file, if no key is given as a parameter then there is no encryption."
              echo ""
              echo "-r, --regex:"
              echo "    Encrypted-regex, used by age. Default: '(hostname|identity|name)'"
	      exit 0
              ;;
            -*|--*=) 
              echo "Error $1 not supported" >&2
              exit 1
              ;;
            *) 
              shift
              ;;
          esac
        done

	# No encryption if no public key is given
	if [ -z $age_public_keys ]
	then
		${shoji}/bin/shoji convert ssh -k $keys_directory -o $output $ssh_config  
	else
		age_bin=${pkgs.age}/bin/age
		${shoji}/bin/shoji convert ssh -u -k $keys_directory $ssh_config | ${pkgs.sops}/bin/sops --encrypt --encrypted-regex $encrypted_regex --age $age_public_keys --input-type yaml --output $output /dev/stdin
	fi

      '';
    in
    {
      inherit shoji shojiInitAgeScript;
    };
  in {

    packages = genAttrs systems packagesForSystem;
    defaultPackage = forAllSystems (system: self.packages.${system}.shojiInitAgeScript);

  # Generate yaml file and encrypts it with given param
    apps = forAllSystems (system: {
      shoji-init = {
        type = "app";
        program = "${self.packages.${system}.shojiInitAgeScript}/bin/shoji-init";
      };
    });
};
}
