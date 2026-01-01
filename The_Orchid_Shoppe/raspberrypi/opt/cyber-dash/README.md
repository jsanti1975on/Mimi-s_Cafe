# User workstation launches cyber dash with launcher .exe file (Windows POS station)
- The kioske style .exe opens the http dashboard
- User can upload a file (jumpbox/sinkhole/vulnerable web app)
- User can browse uploads 
- User can select button Tux Talks (Links to vSphere Host,DVWA,IoT Dashboard
- User can Open Cheats dashboard (web ui with common tools. Base64 challenge)

# From http dashboard move to one below
- East Side Server: 2nd http dashboard (IoT Subnet) <= Move to vlan...
- OWASP (DVWA)
- Pi-hole Dashboard (Logs,Charts,Settings)
- vSphere Host
- coming: virtual machine (e.g. Attacker Machine)
- unused buttons

## East Side Server: directory
```bash
dubz@dubzPi:/opt/cyber-dash $ tree
.
├── assets
│   └── tux-speech.txt
├── cheats
│   ├── css
│   │   ├── style.css
│   │   └── Update-Me
│   ├── dash.js
│   ├── data
│   │   └── tools.json
│   ├── index.html
│   ├── js
│   │   └── cheats.js
│   ├── scripts
│   │   └── server.py
│   ├── style.css
│   ├── tools
│   │   ├── dirsearch.html
│   │   ├── ffuf.html
│   │   ├── gobuster.html
│   │   ├── hashcat.html
│   │   ├── hydra.html
│   │   ├── john.html
│   │   ├── links.html
│   │   ├── nmap.html
│   │   └── sandbox.html
│   ├── txt
│   │   ├── dirsearch.txt
│   │   ├── ffuf.txt
│   │   ├── gobuster.txt
│   │   ├── hashcat.txt
│   │   ├── hydra.txt
│   │   ├── john.txt
│   │   ├── links.txt
│   │   └── nmap.txt
│   └── uploads
├── files
│   ├── ...
│   ├── ...
│   ├── ...
│   ├── ...
│   ├── ...
│   ├── ...
│   ├── ... 
│   ├── ...
│   ├── ...
│   └── ...
├── index.html
├── LOG_FILE
├── scripts
│   ├── server.py
│   └── start-dashboard.sh
├── style.css
├── tux-talks.html
├── uploads
│  |_
└── uploads_old/

```

### To Do
- Cont. Active Directory GPO settings
- 
