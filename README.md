# ESXi RAG Infrastructure Expansion

```bash
The Mimi’s Cafe cyber range is being expanded with a dedicated ESXi RAG infrastructure designed to preserve and organize technical coursework for retrieval-augmented generation (RAG). An OptiPlex 3060 running ESXi serves as the virtualization host, using a lightweight Ubuntu 26.04 LTS golden template to deploy small, purpose-built RAG nodes such as rag-winadmin, with future nodes dedicated to Linux, Cyber Operations, Information Security, and other coursework. Each node will maintain its own vector data, source documents, ingestion workflows, models, logs, and backups under a standardized /srv/rag structure while sharing a repeatable deployment configuration that includes VMware Tools, Docker, Python, PowerShell, Git, DNS, Kerberos, SSSD, and Active Directory integration with the dubzfort.corp domain. The first node, rag-winadmin, is now successfully registered in DNS, discovering AD services, obtaining Kerberos tickets, and authenticating through the domain, establishing the foundation for a scalable cluster of course-specific knowledge servers within the Mimi’s Cafe lab environment.
```

# Project Flow: IoT Room has a real POS terminal domain joined

## Tools: Clockwise
- Monitor
- Thin Client
- Keyboard
- Mouse
- KVM Switch
- Small Form Factor PC
- 2020 Gaming Rig (128 Gigs of Ram)
-   Hyper-V => http dash boards => Host Microsoft Servers and two ubuntu servers.
-   => Shared WIN11 machine
-   => EXCH Server
-   => FSRM

## Tools Cont.
- Media
- Rack -> NGFW -> -> GATE 
- Rasp Pi HTTP DASH "ETHICAL HACKING DASH/SYNTAX HELPER"
- AP -> Reverse Proxy https://ubuntu-gui.dubzfort.corp/ -> "SIMPLE HTTP SERVER" Orchid,Doc,Media Mobile uploader
- Python shuttle move files to directories (e.g.) doc_Files'sName => moves to Documents dir
- -> Cisco Catalyst 3560 POE-8 -> Cisco RV340 <--- Routes Airgapped Linux clusters coming Security Onion
- -> This will bridge to another Cisco Catalyst 3560 POE-8 in the N/E corner inside half rack -> Windows10HyperV Role
- To Be Contin - Time to keep building......

<img width="622" height="695" alt="2026-08-08 01_09_05-Greenshot" src="https://github.com/user-attachments/assets/b74f8d81-0708-468f-b003-f8151314f625" />

 
# Below are notes as moving forward artifacts and are temp.

```bash
This project established secure, routed RDP access from the management workstation ABS.dubzfort.corp (10.10.10.21) to the Hyper-V server HV02.dubzfort.corp (172.20.10.104) across the FortiGate and pfSense firewalls. Host-specific address objects and TCP 3389 policies were created, NAT was disabled to preserve the original source address, and pfSense received a static return route for 10.10.10.0/24 through the FortiGate WAN gateway at 172.20.20.2. DNS resolution, Windows Firewall restrictions, routing, TCP connectivity, and the final RDP login were successfully validated, creating a secure and repeatable management path that can scale as the cyber range grows.
```
# Almost mastering Notion AI for ledger 

<img width="1933" height="1008" alt="notion-dialed-in" src="https://github.com/user-attachments/assets/2b9d955f-a420-44d1-b715-6e2285af7d8c" />


