# OpenVPNTool

This is a set of command line tools to install and configure OpenVPN with a basic configuration specifically for Ubuntu 16.04 and 14.04 with ufw.  This project also contains a client 
generator for making single file .ovpn client files that can then be distributed.

## Getting Started
```
git clone https://github.com/akoerner/OpenVPNTool.git && cd OpenVPNTool
```

### Prerequisites

Ubuntu 16.04 LTS or Ubuntu 14.04 LTS and ufw

### Basic Usage
```
sudo sh openvpn_install.sh -n <server name>  -i <interface> -F
```

Example
```
sudo sh openvpn_install -n SomeServer -i eth0 -F
```
The -F flag does a full install.
NOTE: This enables ufw! Don't lock yourself out by blocking the ssh port! Be sure you actually want ufw enabled.

View the help for more informaiton
```
sh openvpn_install.sh -h
```

## Client Generator
The client generator generates openvpn client keys using the easy-rsa build-key tool and creates  single distributable .ovpn files.
```
sudo sh generate_client.sh -c client1 -o . -b base.conf
```

View the help for more informaiton
```
openvpn_install.sh -h
```


## Authors
Andrew Koernerv - andrew@k0ner.com



## License
[LICENSE.md](LICENSE.md)
