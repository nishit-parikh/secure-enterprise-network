# Security controls and tests

Every control is proven with a **pass/fail pair**: the allowed path works, the blocked path
fails, and a log line shows *which* control blocked it. A timeout on its own could just
mean a host is down.

## Stage 01 · Segmented core network

| ID | Control | Test | Pass criteria |
|---|---|---|---|
| T-01 | Each zone is a separate 802.1Q VLAN | `ovs-vsctl show`, `ovs-appctl fdb/show br-lan` on both routers | Tags 10/20 (r2), 30 (r1), 99 (both); host MACs learned under their own VLAN; gateway IPs only on SVIs |
| T-02 | Inter-zone routing via authenticated OSPF | `show ip ospf neighbor`, `show ip ospf interface vlan99`, `show ip route ospf` | Neighbour Full on vlan99; MD5 shown; r2 learns DMZ + default, r1 learns Users + Infra |
| T-03 | Configuration survives reboot | Reboot both routers | Services active, IPs on SVIs, OSPF Full, nftables loaded, with no manual steps |
| T-04 | Users get addresses through the r2 relay | Release/renew on emp01 and admin | emp01 in .20-.200, gateway .1, DNS 10.10.10.11; admin keeps .2 |
| T-05 | DMZ gets reservations through the r1 relay | Renew on public while capturing on r1 | public = 10.10.30.10; DISCOVER/OFFER/REQUEST/ACK seen on vlan30 |
| T-06 | Private DNS answers trusted clients | Forward, SRV and reverse lookups from emp01 | All answered by 10.10.10.11 |
| T-07 | Private DNS unreachable from DMZ/External | Query 10.10.10.11 from the attacker and from a DMZ server | Timeouts; r1 logs `R1-EXT-INTERNAL-DROP` / `R1-DMZ-INTERNAL-DROP … DPT=53` |
| T-08 | Public DNS exposes only public names | Query public and internal names on 10.10.30.12 | public/shop/www resolve for all; `internal.corp.local` → NXDOMAIN |
| T-09 | Public DNS is not an open resolver | Resolve an Internet name via 10.10.30.12 from the attacker, then from the DMZ | Attacker: REFUSED; DMZ: resolves |
| T-10 | Public websites reachable by everyone | Browse public and shop from attacker, external user, emp01 | HTTP 200/30x everywhere |
| T-11 | Intranet reachable from Users only | Request `internal` from emp01, attacker, public | emp01 loads; others time out; r1 logs drops |
| T-12 | Domain logon and file share | Log on to emp01 as a domain user, map the share | DC located via DNS SRV; share readable |
| T-13 | External can't initiate into internal zones | `ping`, `nmap -Pn 10.10.10.0/24` from attacker | All filtered; `R1-EXT-INTERNAL-DROP` logged |
| T-14 | DMZ can't initiate into internal zones | `nc -zv 10.10.10.12 445` from public | Fails; `R1-DMZ-INTERNAL-DROP` logged |
| T-15 | Only admin manages devices over SSH | SSH from admin and from emp01 to routers and servers | admin succeeds; emp01 times out |
| T-16 | ICMP/traceroute work on permitted paths | `traceroute` Users → DMZ and Internet | Hops r2 → r1 → destination |
| T-17 | Firewalls are default-deny and log | `nft list ruleset`; drop logs during tests | `policy drop` on input/forward; DROP entries present |

## Stage 02 · Host firewall automation

| ID | Control | Test | Pass criteria |
|---|---|---|---|
| T-20 | Every Linux server is default-deny | `sudo nft list ruleset` on each host | `policy drop` on input, forward, output |
| T-21 | Safe rollout | `ansible-playbook site.yml --check --diff`, then apply | No lockout; `nft -c` validation on every host |
| T-22 | Explicit blocks are logged | SSH dns-dhcp from admin vs. from mgmt | admin blocked with `dns-dhcp-BLOCK` logged; mgmt works |
| T-23 | Per-zone resolver enforced | DNS from a DMZ host to the private DNS | Dropped on the host's output chain |
| T-24 | Windows firewalls enforced | WinRM to admin from mgmt vs. from another host | mgmt succeeds; others blocked |

## Stage 03 · DMZ threat inspection

| ID | Control | Test | Pass criteria |
|---|---|---|---|
| T-30 | Web only via IPS → WAF | Normal browse from attacker | DVWA 302, Juice Shop 200 |
| T-31 | IPS drops SQL injection in-path | `curl -m5 "http://<wan>/?id=1%20union%20select%201"` | `000`; `CUSTOM-IPS SQLi` in `fast.log` |
| T-32 | WAF blocks attack tooling | `curl -A "sqlmap/1.0" http://<wan>/` | `403`; rule 100005 in the audit log |
| T-33 | Backends unreachable directly | `curl -m5 http://10.10.30.22:8080/` from attacker | `000` |

## Stage 04 · Secure remote access (in progress)

| ID | Control | Test | Pass criteria |
|---|---|---|---|
| T-40 | Intranet served over trusted HTTPS | Browse `https://internal.corp.local` from emp01 | Clean padlock; HTTP redirects to HTTPS ✅ |
| T-41 | Public sites over HTTPS at the WAF | Browse `https://public.corp.local` from emp01 | Clean padlock *(pending router rules)* |
| T-42 | VPN clients reach only the jump host | Connect as emp-vpn; try any IP besides jump | Only jump:22 reachable *(pending)* |
| T-43 | Role-based access | emp → intranet ✓, DC ✗; admin → DC ✓ | As stated *(pending)* |
