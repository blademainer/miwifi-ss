#!/bin/sh

clear
echo "#############################################################"
echo "# Install Shadowsocks for Miwifi"
echo "#############################################################"

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "Error:This script must be run as root!" 1>&2
   exit 1
fi
cd /userdisk/data/
rm -f shadowsocks_miwifi.tar.gz
curl -k -o shadowsocks_miwifi.tar.gz https://raw.githubusercontent.com/blademainer/miwifi-ss/master/r2d/shadowsocks_miwifi.tar.gz
tar zxf shadowsocks_miwifi.tar.gz

# Config shadowsocks init script
cp ./shadowsocks_miwifi/myshadowsocks /etc/init.d/myshadowsocks
chmod +x /etc/init.d/myshadowsocks

#config setting and save settings.
echo "#############################################################"
echo "#"
echo "# Please input your shadowsocks configuration"
echo "#"
echo "#############################################################"
echo ""
echo "请输入服务器IP:"
read serverip
echo "请输入服务器端口:"
read serverport
echo "请输入密码"
read shadowsockspwd
echo "请输入加密方式"
read method

# Config shadowsocks
cat > /etc/shadowsocks.json<<-EOF
{
  "server":"${serverip}",
  "server_port":${serverport},
  "local_address":"127.0.0.1",
  "local_port":1081,
  "password":"${shadowsockspwd}",
  "timeout":600,
  "method":"${method}"
}
EOF

#config dnsmasq
mkdir -p /etc/dnsmasq.d
cp -f ./shadowsocks_miwifi/dnsmasq_list.conf /etc/dnsmasq.d/dnsmasq_list.conf

#config firewall
cp -f /etc/firewall.user /etc/firewall.user.back
echo "ipset -N gfwlist iphash -! " >> /etc/firewall.user
echo "iptables -t nat -A PREROUTING -p tcp -m set --match-set gfwlist dst -j REDIRECT --to-port 1081" >> /etc/firewall.user

#restart all service
/etc/init.d/dnsmasq restart
/etc/init.d/firewall restart
/etc/init.d/myshadowsocks start
/etc/init.d/myshadowsocks enable

#install successfully
rm -rf /userdisk/data/shadowsocks_miwifi
rm -f /userdisk/data/shadowsocks_miwifi.tar.gz
echo ""
echo "Shadowsocks安装成功！"
echo ""
exit 0
