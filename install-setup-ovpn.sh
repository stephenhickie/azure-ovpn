exit 0
sudo su - ## make me root
#if [ -f ~/client1.ovpn ] ; then logger -t install "already installed SMS" && exit ; else logger -t install "install openvpn SMS" ; fi

apt-get install openvpn easy-rsa -y
gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz > /etc/openvpn/server.conf
sed -i "s/dh1024/dh2048/g" /etc/openvpn/server.conf
sed -i "s/port 1194/port 443/g" /etc/openvpn/server.conf
sed -i "s/proto udp/proto tcp/g" /etc/openvpn/server.conf
subnet=$(netstat -tr | head -n 4 | tail -n 1 | cut -d ' ' -f1)
netmask=$(netstat -tr | head -n 4 | tail -n 1 | cut -d ' ' -f23)
echo "push route $subnet $netmask" >> /etc/openvpn/server.conf
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i "s/#net.ipv4.ip_forward/net.ipv4.ip_forward/g" /etc/sysctl.conf
ufw allow https
sed -i "s/DEFAULT_FORWARD_POLICY=\"DROP\"/DEFAULT_FORWARD_POLICY=\"ACCEPT\"/g" /etc/default/ufw
rm -rf /etc/openvpn
cp -r /usr/share/easy-rsa/ /etc/openvpn
cd /etc/openvpn/easy-rsa
source vars
touch /etc/openvpn/easy-rsa/keys/index.txt
echo 490B82C4000000000075 > /etc/openvpn/easy-rsa/keys/serial
./pkitool --initca
./pkitool --server server
./pkitool client1
cp /etc/openvpn/easy-rsa/keys/ca* /etc/openvpn/
cp /etc/openvpn/easy-rsa/keys/server.* /etc/openvpn/

mv /etc/ufw/before.rules ~/
head ~/before.rules -n 10 >> /etc/ufw/before.rules
cat <<EOF >> /etc/ufw/before.rules
# START OPENVPN RULES
# NAT table rules
*nat
:POSTROUTING ACCEPT [0:0]
# Allow traffic from OpenVPN client to eth0
-A POSTROUTING -s 10.8.0.0/8 -o eth0 -j MASQUERADE
COMMIT
# END OPENVPN RULES
EOF
tail ~/before.rules -n 68 >> /etc/ufw/before.rules

## all thing being equal we should now be able to start the server
server openvpn start
cat <<EOF > ~/client1.ovpn
client
dev tun
proto tcp
persist-key
persist-tun
comp-lzo yes
EOF
echo remote $(dig +short myip.opendns.com @resolver1.opendns.com.) 443 >> ~/client1.ovpn
echo \<ca\> >> ~/client1.ovpn
cat /etc/openvpn/ca.crt >> ~/client1.ovpn
echo \</ca\> >> ~/client1.ovpn

echo \<cert\> >> ~/client1.ovpn
cat /etc/openvpn/easy-rsa/keys/client1.crt >> ~/client1.ovpn
echo \</cert\> >> ~/client1.ovpn

echo \<key\> >> ~/client1.ovpn
cat /etc/openvpn/easy-rsa/keys/client1.key >> ~/client1.ovpn
echo \</key\> >> ~/client1.ovpn
