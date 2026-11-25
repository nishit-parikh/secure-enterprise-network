#!/bin/bash
# /usr/local/sbin/ovs-l3.sh on r1 (edge router)
# Re-applies the OVS bridge, access ports and SVI gateway IPs at every boot.
# --may-exist makes it safe to re-run. The WAN (ens33) stays outside OVS.
set -euo pipefail
BR=br-lan

ovs-vsctl --may-exist add-br $BR -- set bridge $BR other-config:hwaddr='"02:00:00:00:01:00"'
ovs-vsctl --may-exist add-port $BR ens38 -- set port ens38 tag=30    # DMZ access port
ovs-vsctl --may-exist add-port $BR ens37 -- set port ens37 tag=99    # transit access port

# add_svi <svi> <vlan> <physical-nic> <cidr>
# Each SVI reuses its NIC's MAC so host ARP caches stay valid.
add_svi () {
  local mac; mac=$(cat /sys/class/net/$3/address)
  ovs-vsctl --may-exist add-port $BR $1 -- set port $1 tag=$2 -- set interface $1 type=internal mac="\"$mac\""
  ip addr flush dev $3
  ip link set $3 up
  ip link set $1 up
  ip addr replace $4 dev $1
}

add_svi vlan30 30 ens38 10.10.30.1/24
add_svi vlan99 99 ens37 192.168.8.193/30
