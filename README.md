# OpenVPNTool

This is a set of command line tools to install and configure OpenVPN with a basic configuration specifically for Ubuntu 16.04 and 14.04 with ufw.  This project also contains a client 
generator for making single file .ovpn client files that can then be distributed.

## Getting Started

### Prerequisites

Ubuntu 16.04 LTS or Ubuntu 14.04 LTS and ufw

Clone the repository
```
git clone https://github.com/akoerner/OpenVPNTool.git && cd OpenVPNTool
```

### Basic Usage

#### OpenVPNTool
```
sudo sh openvpn_install.sh --server-name <server name>  --interface <interface> --full-install
```

##### Examples
```
sudo sh openvpn_install.sh --server-name SomeServer --interface eth0 --full-install
```
The -F flag does a full install.
NOTE: This enables ufw! Don't lock yourself out by blocking the ssh port! Be sure you actually want ufw enabled.

View the help for more information
```
sh openvpn_install.sh -h
```

#### Client Generator
The client generator generates openvpn client keys using the easy-rsa build-key tool and creates  single distributable .ovpn files.

##### Examples

###### Example #1
Generate a client1.ovpn using the baseconfig base.conf and output to the current working directory in interactive mode.  Interactive mode requires user input. Client keys will be generated.
```
sudo sh generate_client.sh --client-name client1 --output-directory . --base-config base.conf
```
client1.opvn can then be distributed to a user.

###### Example #2
Generate a client2.opvn using the baseconfig base.conf and output to the current working directory in silent mode.  Silent mode requires no user input.  All client parameters are set to the default and new client keys will be generated. 
```
sh generate_client.sh --client-name client2 --base-config base.conf --output-directory . --slient-mode
```

###### Example #3
Regenerate a client1.ovpn distributable file but do not regenerate keys.  Preexisting keys will be used to compile the client1.opvn file and the output file client1.ovpn will be output to the current working directory.  This can be used to simply regenerate the distributable ovpn file.
```
sh generate_client.sh --client-name client2 --base-config base.conf --output-directory . --silent-mode --skip-key-generation
```

###### Example #3
Generate client1 keys and do not compile an output client1.opvn distributable file in silent mode.  This can be used to only generate the client keys.
```
sh generate_client.sh --client-name client2 --base-config base.conf --output-directory . --silent-mode --skip-output-file-generation
```


View the help for more information
```
sh openvpn_install.sh -h
```
### The Dark Arts
Here are a few one line incantations of awesomeness


Generate 10 clients
```
mkdir clients && for ((n=0;n<10;n++)); do sh generate_client.sh --client-name client$n --output-directory clients/ --base-config base.conf --silent-mode; done
```

### Bonus For OpenVZ Containers
Installing OpenVPN in an OpenVZ container one-liner

There is a weird issue when installing OpenVPN inside a OpenVZ container that prevents the system.d service from running.  This one-liner installs, configures and patches openvpn for this instance.
```
sh openvpn_install.sh --server-name server --interface eth0 --install-openvpn --build-server-config-file --enable-packet-forwarding --modify-ufw-rules --reload-ufw --build-ca --silent-mode && sh openvz_tools/openvz_openvpn_patch.sh && sh openvpn_install.sh --server-name server --start-openvpn-server 
```

## Authors
Andrew Koerner - andrew@k0ner.com



## License
[LICENSE.md](LICENSE.md)


To those who visit here, we wish a safe journey and the joy of discovery.
