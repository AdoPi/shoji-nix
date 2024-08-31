echo "[Test] Simple case using all options"

nix run ..#shoji-init -- -k ssh -c ssh/config -o ssh.yaml -a $(cat age/key.txt | grep public | grep -oP "public key: \K(.*)")

nix run ..#shoji-run -- -k home-ssh-test -o home-ssh-test/config -p age/key.txt -y ssh.yaml

echo "[Test] auto generating age key file"

rm -f age.txt
nix run ..#shoji-init -- -k ssh -c ssh/config -o ssh-g.yaml -g age.txt
nix run ..#shoji-run -- -k home-ssh-test-g -o home-ssh-test-g/config -p age.txt -y ssh-g.yaml
rm -f age.txt

echo "[Test] using -a and -g at the same time should not be possible"

# Testing with -g and -a at the same time
nix run ..#shoji-init -- -k ssh -c ssh/config -o ssh-g.yaml -a $(cat age/key.txt | grep public | grep -oP "public key: \K(.*)") -g hello.txt 

echo "[Test] Using -g without an argument"

nix run ..#shoji-init -- -k ssh -c ssh/config -o ssh-g.yaml -g 

echo "[Test] Using -k without an argument"

nix run ..#shoji-init -- -c ssh/config -o ssh-g.yaml -a $(cat age/key.txt | grep public | grep -oP "public key: \K(.*)") -k
