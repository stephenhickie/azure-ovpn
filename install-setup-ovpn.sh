#sudo su - ## make me root
if [ -f ~/client1.ovpn ] ; then logger -t install "already installed SMS" && exit ; else logger -t install "install openvpn SMS" ; fi

apt-get install openvpn easy-rsa -y
gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz > /etc/openvpn/server.conf
sed -i "s/dh1024/dh2048/g" /etc/openvpn/server.conf
sed -i "s/port 1194/port 443/g" /etc/openvpn/server.conf
sed -i "s/proto udp/proto tcp/g" /etc/openvpn/server.conf
subnet=$(netstat -tr | head -n 4 | tail -n 1 | cut -d ' ' -f1)
netmask=$(ifconfig eth0 | grep Mask | cut -d':' -f 4)
echo "push route $subnet $netmask" >> /etc/openvpn/server.conf
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i "s/#net.ipv4.ip_forward/net.ipv4.ip_forward/g" /etc/sysctl.conf
ufw allow https
sed -i "s/DEFAULT_FORWARD_POLICY=\"DROP\"/DEFAULT_FORWARD_POLICY=\"ACCEPT\"/g" /etc/default/ufw
rm -rf /etc/openvpn/easy-rsa/
cp -r /usr/share/easy-rsa/ /etc/openvpn
cd /etc/openvpn/easy-rsa
mkdir keys
source vars
touch /etc/openvpn/easy-rsa/keys/index.txt
echo 490B82C4000000000075 > /etc/openvpn/easy-rsa/keys/serial

## Ahh .. the diffe hack  ... sorry about this crypto peeps
#openssl dhparam -out /etc/openvpn/dh2048.pem 2048
cat <<EOF > /etc/openvpn/dh2048.pem
-----BEGIN DH PARAMETERS-----
MIIBCAKCAQEAosbDpJV+2hSxgZW/KKAtLRI0ARJlv+82kPoyeJh6uprCcGfHq/vV
4QXB1esAnJ8v1/zKaBAOiGUpBihYvM6j9PWq0RlLSmWCvXyaVJ5V0GMK3zYTUd1h
yMzk7eQx2krTHwq6okTuSJDsxlbNrbN8zDIuStMe9FEr9ASfx8p4t/qYS9OMD5DE
8zfxBV2pTg1195UHqpzaf8HOjstGSTCpIGgrifrTDmcA1UnZIKjXdCKok0xXAcDF
D0x7G9vFnEz9+qR9jY56R6sR+pW6r/+DN7V0tPQ29Ro4f5DSNdsKeZQsJjZZBTS0
mvhZ0msr6kn9kujczJEQL0XwAdqY9x7aGwIBAg==
-----END DH PARAMETERS-----
EOF

./pkitool --initca
./pkitool --server server
./pkitool client1
cp /etc/openvpn/easy-rsa/keys/ca* /etc/openvpn/
cp /etc/openvpn/easy-rsa/keys/server.* /etc/openvpn/
ufw disable
#mv /etc/ufw/before.rules /etc/ufw/before.rules.bkp
#head /etc/ufw/before.rules.bkp -n 10 >> /etc/ufw/before.rules
#cat <<EOF >> /etc/ufw/before.rules
## START OPENVPN RULES
## NAT table rules
#*nat
#:POSTROUTING ACCEPT [0:0]
## Allow traffic from OpenVPN client to eth0
#-A POSTROUTING -s 10.8.0.0/8 -o eth0 -j MASQUERADE
#COMMIT
## END OPENVPN RULES
#EOF
#tail /etc/ufw/before.rules.bkp -n 68 >> /etc/ufw/before.rules
#yes | ufw enable
## all thing being equal we should now be able to start the server

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

service openvpn restart
