# OpenVPNTool

This is a set of command line tools to install and configure OpenVPN with a basic configuration specifically for Ubuntu 16.04 and 14.04 with ufw.  This project also contains a client 
generator for making single file .ovpn client files that can then be distributed.

## Prerequisites

Ubuntu 16.04 LTS or Ubuntu 14.04 LTS and ufw

## Getting Started
Clone the repository
```
git clone https://github.com/akoerner/OpenVPNTool.git && cd OpenVPNTool
```

### Basic Usage

#### OpenVPNTool
```
sudo sh openvpn_install.sh -n <server name>  -i <interface> -F
```

##### Examples
```
sudo sh openvpn_install -n SomeServer -i eth0 -F
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
sudo sh generate_client.sh -c client1 -o . -b base.conf
```
client1.opvn can then be distributed to a user.

###### Example #2
Generate a client2.opvn using the baseconfig base.conf and output to the current working directory in silent mode.  Silent mode requires no user input.  All client parameters are set to the default and new client keys will be generated. 
```
sh generate_client.sh -c client2 -b base.conf -o . -s
```

###### Example #3
Regenerate a client1.ovpn distributable file but do not regenerate keys.  Preexisting keys will be used to compile the client1.opvn file and the output file client1.ovpn will be output to the current working directory.
```
sh generate_client.sh -c client2 -b base.conf -o . -s -x
```

###### Example #3
Generate client1 keys and do not compile an output client1.opvn distributable file in silent mode.
```
sh generate_client.sh -c client2 -b base.conf -o . -s -O
```


View the help for more information
```
sh openvpn_install.sh -h
```


## Authors
Andrew Koerner - andrew@k0ner.com



## License
[LICENSE.md](LICENSE.md)


To those who visit here, we wish a safe journey and the joy of discovery.
