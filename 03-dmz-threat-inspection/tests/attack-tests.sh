#!/usr/bin/env bash
# Run from the external attacker host. TARGET is the edge router's WAN address.
# Always use a timeout on attack requests: an IPS drop looks like a hang, so
# "000" after 5 seconds means the request was blocked.
set -u
TARGET="${1:-192.168.209.129}"

echo "== Baseline (should succeed)"
curl -s -o /dev/null -w "DVWA:        %{http_code}  (expect 302)\n" "http://$TARGET/"
curl -s -o /dev/null -w "Juice Shop:  %{http_code}  (expect 200)\n" "http://$TARGET:8081/"

echo "== Attacks (should be blocked)"
curl -m5 -s -o /dev/null -w "SQLi:        %{http_code}  (expect 000 = IPS drop)\n" "http://$TARGET/?id=1%20union%20select%201"
curl -m5 -s -o /dev/null -w "XSS:         %{http_code}  (expect 000 = IPS drop)\n" "http://$TARGET/?q=%3Cscript%3Ealert(1)%3C/script%3E"
curl -m5 -s -o /dev/null -w "Traversal:   %{http_code}  (expect 000 = IPS drop)\n" "http://$TARGET/?file=../../etc/passwd"
curl -m5 -s -o /dev/null -w "Scanner UA:  %{http_code}  (expect 403 = WAF block)\n" -A "sqlmap/1.0" "http://$TARGET/"

echo "== Watch the sensor while this runs:  sudo tail -f /var/log/suricata/fast.log"
