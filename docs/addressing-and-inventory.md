# Addressing and inventory

## Zones

| Zone | VLAN | Subnet | Gateway (SVI) | OSPF area | Access port |
|---|---|---|---|---|---|
| Users | 10 | 172.16.0.0/24 | r2 vlan10 · 172.16.0.1 | 1 | r2 ens37 |
| Infrastructure | 20 | 10.10.10.0/24 | r2 vlan20 · 10.10.10.1 | 2 | r2 ens38 |
| DMZ | 30 | 10.10.30.0/24 | r1 vlan30 · 10.10.30.1 | 3 | r1 ens38 |
| Transit | 99 | 192.168.8.192/30 | r1 .193 · r2 .194 | 0 | r1 ens37 · r2 ens33 |
| External | none | 192.168.209.0/24 | NAT · r1 WAN .129 | n/a | r1 ens33 (outside OVS) |
| VPN tunnel pool | n/a | 10.8.0.0/24 | vpn host | n/a | emp .10 · admin .20 |

## Hosts

| Host | Zone | IP | OS | Role | Added in |
|---|---|---|---|---|---|
| r1 | Edge | 192.168.209.129 · 10.10.30.1 · 192.168.8.193 | Ubuntu | Edge router: NAT, OVS, FRR, nftables, DHCP relay | 01 |
| r2 | Internal | 172.16.0.1 · 10.10.10.1 · 192.168.8.194 | Ubuntu | Internal router: OVS, FRR, nftables, DHCP relay | 01 |
| admin | Users | 172.16.0.2 (reserved) | Windows 10 | Management workstation (scanners, SSH, RDP) | 01 |
| emp01 | Users | DHCP 172.16.0.20-200 | Windows 10 | Employee workstation, domain member | 01 |
| ad | Infra | 10.10.10.10 (static) | Windows Server | AD DS domain controller, `corp.local` | 01 |
| dns-dhcp | Infra | 10.10.10.11 (static) | Ubuntu | Private BIND9 + ISC DHCP | 01 |
| file | Infra | 10.10.10.12 | Ubuntu | Samba file share | 01 |
| internal | Infra | 10.10.10.13 | Ubuntu | Intranet (Dolibarr on Apache) | 01 |
| mgmt | Infra | 10.10.10.14 | Ubuntu | Ansible control node | 02 |
| public | DMZ | 10.10.30.10 | Ubuntu | Corporate website (Apache, WordPress) | 01 |
| shop | DMZ | 10.10.30.11 | Ubuntu | E-commerce website (Apache, WordPress) | 01 |
| dns-public | DMZ | 10.10.30.12 | Ubuntu | Public BIND9 | 01 |
| waf | DMZ | 10.10.30.20 | Ubuntu | Nginx + ModSecurity reverse proxy | 03 |
| ids | DMZ | 10.10.30.21 | Ubuntu | Suricata inline IPS | 03 |
| targets | DMZ | 10.10.30.22 | Ubuntu | Docker: DVWA, OWASP Juice Shop | 03 |
| vpn | DMZ | 10.10.30.23 | Ubuntu | OpenVPN server + Easy-RSA CA | 04 |
| jump | DMZ | 10.10.30.24 | Ubuntu | SSH bastion | 04 |
| attacker | External | 192.168.209.130 | Kali Linux | Penetration testing | 01 |
| external user | External | 192.168.209.131 | n/a | Internet client | 01 |

## Firewall management model

| Host type | Firewall | Managed by |
|---|---|---|
| Routers (r1, r2) | nftables zone policy | Hand-managed (stage 01 + `*-additions.nft`) |
| Forwarding hosts (ids, targets, vpn, jump) | nftables, hand-written | Hand-managed: they must forward or NAT, which the endpoint template forbids |
| Linux endpoints | nftables from template | Ansible `site.yml` |
| Windows servers / admin | Windows Defender Firewall | Ansible over WinRM |
| Employee PCs | Windows Defender Firewall | AD Group Policy |
