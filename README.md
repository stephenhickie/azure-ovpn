# azure-ovpn

This will build an

#Pre-requisites

1. An Azure subscription
2. Azure CLI (original, not hot and spicy 2.0) install on your local machine
3. a machine in your source environment that can run OpenVPN, and can forward from on interfaces


#How to use
1. clone the repo
2. edit or copy ms-cli-params
3. login to Azure using azure login and set the mode to ARM. You can do this by removing the first few comments from msft-cli if you like.
4. SSH onto the machine using the public IP address. The address is in the script output
5. sudo to root (sudo su -)
6. in roots home directory, there is a client1.ovpn file. you can copy that file to your local machine .. i usually just cat it out and make a new one on my machine
7. import that file into your OpenVPN client on your source system. As long as your source system has access to the public IP address, you should be able to start the VPN and connect
8. You will need to add some routes into your local machines or in your network's route table if you want your source systems to be able to find Azure. You will also need a route back from Azure, so add the source system's IP ranges into the Azure route table.



# Things to note
The SSL cert configuration information is standard based on easy-rsa.  if you get excited you can regenerate your own. This doesn't currently support password based auth, feel free to make the necessary changes and send me a pull request. probably not a good idea to change openvpnrouteprefix or vm1imageurn.  This will break it.  If you want to make changes to the NSG afterwards, that is fine too.
