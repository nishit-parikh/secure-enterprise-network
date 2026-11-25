# Verification plan

Each control is shown as a pass/fail pair: the allowed path works and the blocked path
fails, with a router log line proving the firewall blocked it (not just a host being down).

## 1. The VLANs are real 802.1Q VLANs

| Check | Command | Expected |
|---|---|---|
| Port tags | `sudo ovs-vsctl show` | Each zone port shows its `tag:`; SVIs are `type: internal` |
| Access port detail | `sudo ovs-vsctl list port ens38` | `tag: 30` on r1 |
| Per-VLAN MAC learning | `sudo ovs-appctl fdb/show br-lan` | Host MACs listed under their VLAN number |
| IPs only on SVIs | `ip -br a` | Addresses on `vlan*` (and r1's WAN), none on switch ports |

## 2. Routing (OSPF)

| Check | Command | Expected |
|---|---|---|
| Adjacency | `sudo vtysh -c "show ip ospf neighbor"` | Peer in state **Full** on vlan99 |
| Authentication | `sudo vtysh -c "show ip ospf interface vlan99"` | MD5 authentication enabled |
| Learned routes | `ip route \| grep ospf` | r2: DMZ + default; r1: Users + Infra |
| ABR role | `sudo vtysh -c "show ip ospf"` | "This router is an ABR" |
| Inter-zone path | `traceroute 10.10.30.10` from Users | r2 → r1 → DMZ |

## 3. Zone isolation

| From | Test | Expected | Evidence |
|---|---|---|---|
| External attacker | `ping 10.10.10.10`, `nmap -Pn 10.10.10.0/24` | Timeout, all filtered | `R1-EXT-INTERNAL-DROP` on r1 |
| DMZ server | `nc -zv 10.10.10.12 445` | Fails | `R1-DMZ-INTERNAL-DROP` on r1 |
| Users workstation | `\\10.10.10.12\share` | Works | (contrast with the DMZ test above) |

Watch drops live: `sudo journalctl -k -f | grep DROP`

## 4. Split-horizon DNS

| Query | From Users | From External |
|---|---|---|
| `internal.corp.local` @ private (10.10.10.11) | 10.10.10.13 | timeout (firewall drop) |
| `internal.corp.local` @ public (10.10.30.12) | NXDOMAIN | NXDOMAIN |
| `shop.corp.local` @ public (10.10.30.12) | resolves | resolves |
| `google.com` @ public (10.10.30.12) | n/a | REFUSED (no open recursion) |

Use `dig @<server> <name>` from Linux; `.local` names can trigger mDNS lookups if no
server is specified.

## 5. Reboot persistence

```bash
sudo reboot
systemctl is-active openvswitch-switch ovs-l3 frr isc-dhcp-relay nftables
ip -br a
sudo vtysh -c "show ip ospf neighbor"
```
