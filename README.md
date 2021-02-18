# openwrt-nanopi-r2s

## 设置OpenVPN client

### 设置接口
```
uci set network.vpn=interface
uci set network.vpn.proto='none'
uci set network.vpn.ifname='tun0'

uci commit network
/etc/init.d/network restart


cat >> /etc/config/network << EOF
config interface 'vpn'
    option proto 'none'
    option ifname 'tun1'
EOF

```

### 设置Firewall Zone
```
cat >> /etc/config/firewall << EOF
config zone
    option name 'VPN_FW'
    option input 'REJECT'
    option output 'ACCEPT'
    option forward 'REJECT'
    option masq '1'
    option mtu_fix '1'
    option network 'VPN'

config forwarding                               
        option dest 'VPN_FW'
        option src 'lan' 
EOF
```

* https://marquistj13.github.io/MyBlog/2018/12/openwrt-openvpn-client-setup/#第二种-openvpn-设置

* https://gist.github.com/willwhui/1febd37a3dd79a503cc8544c3bb18ece