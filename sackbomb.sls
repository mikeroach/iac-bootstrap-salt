# sackbomb.sls

# Mitigate SACK Panic and related vulnerabilities pending Ubuntu kernel fixes.
# Addresses CVE-2019-11477, CVE-2019-11478, and CVE-2019-11479.
# See: https://github.com/Netflix/security-bulletins/blob/master/advisories/third-party/2019-001.md

disable TCP selective acknowledgement:
  sysctl.present:
    - name: net.ipv4.tcp_sack
    - value: 0

block low MSS values:
  iptables.append:
    - table: filter
    - chain: INPUT
    - jump: DROP
    - match: tcpmss --mss 1:500
    - protocol: tcp
    - save: true
