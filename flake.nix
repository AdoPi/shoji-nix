{
  description = "Bundle and encrypt your SSH keys with Nix";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/release-24.05";
  outputs = {
    self,
    nixpkgs,
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

      shoji = pkgs.callPackage ./pkgs/shoji.nix { };

      # run this to decrypt yaml and install your .ssh folder 
      shojiAgeRunScript = pkgs.writeShellScriptBin "shoji-run" ''
        #!/usr/bin/env bash
        keys_directory="~/.ssh" # output path
        ssh_config="~/.ssh/config" # output config
        yaml_config="ssh.yaml" # input file
	age_private_key_file="" # private key to decrypt input file

        # Parsing options
        while (( "$#" )); do
          case "$1" in
            -k|--keys-directory)
              if [ -n "$2" ] && [ $${2:0:1} != "-" ]; then
                keys_directory=$2
                shift 2
	      else
                echo "Error : $1 needs one arg." >&2
                exit 2
              fi
              ;;
            -o|--output)
              if [ -n "$2" ] && [ $${2:0:1} != "-" ]; then
                output=$2
                shift 2
	      else
                echo "Error : $1 needs one arg." >&2
                exit 2
              fi
              ;;
            -p|--age-private-key)
              if [ -n "$2" ] && [ $${2:0:1} != "-" ]; then
                age_private_key_file=$2
                shift 2
	      else
                echo "Error : $1 needs one arg." >&2
                exit 2
              fi
              ;;
            -y|--yaml-config)
              if [ -n "$2" ] && [ $${2:0:1} != "-" ]; then
                yaml_config=$2
                shift 2
	      else
                echo "Error : $1 needs one arg." >&2
                exit 2
              fi
              ;;
            -h|--help)
              echo "-k, --keys-directory:"
              echo "    Specifies the location of the directory that contains the ssh keys, usually \$HOME/.ssh."
              echo ""
              echo "-o, --output:"
              echo "    Path to the generated SSH config file."
              echo ""
              echo "-p, --age-private-key:"
              echo "    Private age key which will be used to decrypt the yaml file previously generated by #shoji-init. If your file is not encrypted, this option must be left blank."
              echo ""
              echo "-y, --yaml-config:"
              echo "    Path to the Yaml config file previously generated by Shoji."
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

	ssh_folder=$keys_directory
	ssh_config=$output

	# No encryption if no public key is given
	if [ -z $age_private_key_file ]
	then
		${shoji}/bin/shoji convert yaml -k $keys_directory -o $ssh_config $yaml_config
	else
		age_bin=${pkgs.age}/bin/age
    export SOPS_AGE_KEY_FILE=$age_private_key_file
		${pkgs.sops}/bin/sops exec-file $yaml_config "${shoji}/bin/shoji convert yaml -k $keys_directory -o $ssh_config {}"
	fi
        '';

      # Generate yaml (optionally encrypted) from a ssh config file
      shojiInitAgeScript = pkgs.writeShellScriptBin "shoji-init" ''
        #!/usr/bin/env bash
        keys_directory="~/.ssh"
        ssh_config="~/.ssh/config"
        output="ssh.yaml"
        age_public_keys=""
        encrypted_regex='(hostname|identity|name)'
        generate_age_pkey=false
	age_private_key_path=key.txt

        # Parsing options
        while (( "$#" )); do
          case "$1" in
            -g|--generate-age-key)
              if [ -n "$2" ] && [ $${2:0:1} != "-" ]; then
                age_private_key_path=$2
		generate_age_pkey=true
                shift 2
	      else
                echo "Error : $1 needs one arg." >&2
                exit 2
              fi
              ;;
            -o|--output)
              if [ -n "$2" ] && [ $${2:0:1} != "-" ]; then
                output=$2
                shift 2
	      else
                echo "Error : $1 needs one arg." >&2
                exit 2
              fi
              ;;
            -k|--keys-directory)
              if [ -n "$2" ] && [ $${2:0:1} != "-" ]; then
                keys_directory=$2
                shift 2
	      else
                echo "Error : $1 needs one arg." >&2
                exit 2
              fi
              ;;
            -c|--ssh-config)
              if [ -n "$2" ] && [ $${2:0:1} != "-" ]; then
                ssh_config=$2
                shift 2
	      else
                echo "Error : $1 needs one arg." >&2
                exit 2
              fi
              ;;
            -a|--age-public-keys)
              if [ -n "$2" ] && [ $${2:0:1} != "-" ]; then
                age_public_keys=$2
                shift 2
	      else
                echo "Error : $1 needs one arg." >&2
                exit 2
              fi
              ;;
            -r|--regex)
              if [ -n "$2" ] && [ $${2:0:1} != "-" ]; then
                encrypted_regex=$2
                shift 2
	      else
                echo "Error : $1 needs one arg." >&2
                exit 2
              fi
              ;;
            -h|--help)
              echo "-g, --generate-age-key:"
              echo "    [WIP] Indicates if this program needs to generate an Age key for you."
              echo ""
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
              echo "    Public age keys with which to encrypt the file, if no key is given as a parameter then there is no encryption. In case of -g option, this is used to generate the age key file to this path."
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

        if [ $generate_age_pkey = true ]
        then 
		if [ -z $age_public_keys ]
		then
			# Generating age key
			${pkgs.age}/bin/age-keygen -o $age_private_key_path &> /dev/null
			age_public_keys=$(cat $age_private_key_path | grep public | grep -oP "public key: \K(.*)")
		else
			echo "-a (--age-public-key) and -g (--generate-age-key) are not compatible."
			exit 1
		fi
	fi

	# No encryption if no public key is given
	if [ -z $age_public_keys ]
	then
		${shoji}/bin/shoji convert ssh -k $keys_directory -o $output $ssh_config
	else
		age_bin=${pkgs.age}/bin/age
		${shoji}/bin/shoji convert ssh -u -k $keys_directory $ssh_config | ${pkgs.sops}/bin/sops --encrypt --encrypted-regex $encrypted_regex --age $age_public_keys --input-type yaml --output-type yaml --output $output /dev/stdin
	fi
      '';
    in
    {
      inherit shoji shojiInitAgeScript shojiAgeRunScript;
    };
  in {

    nixosModules = {
      shoji = import ./modules/shoji;
      default = self.nixosModules.shoji;
    };

    packages = genAttrs systems packagesForSystem;
    defaultPackage = forAllSystems (system: self.packages.${system}.shojiInitAgeScript);

  # Generate yaml file and encrypts it with given param
    apps = forAllSystems (system: {
      shoji-init = {
        type = "app";
        program = "${self.packages.${system}.shojiInitAgeScript}/bin/shoji-init";
      };

      shoji-run = {
        type = "app";
        program = "${self.packages.${system}.shojiAgeRunScript}/bin/shoji-run";
      };
    });
};
}
