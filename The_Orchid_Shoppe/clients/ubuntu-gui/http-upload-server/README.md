# HTTP Upload Server (Python3, Subnet-bound)
- lightweight Python 3 web server for file uploads

## Purpose
- Move files from one subnet to another on type-1 hypervisor vms
- Works with jumpboxes - added a config.ini to map a subnet

## Project Directory Structure

```graphql

http-upload-server/
├── uploads/                # [Runtime] Uploaded files saved here
├── index.html              # Upload form shown in the browser
├── server.py               # Main Python HTTP upload server
├── config.ini              # IP address, port, and upload path settings
└── README.md               # Documentation and usage instructions

```

## Security Considerations
- Not authenticated – anyone on the subnet can upload. Use VLAN or firewall segmentation for lab use only.
- Do not expose to the internet unless you add authentication, TLS, and validation.
- Designed for internal CTFs, hacking labs, or jump boxes.

## Future Ideas
- Add systemd service to auto-start
- Add upload logging or basic web UI
- Add .desktop launcher for GUI users
- Optional ZIP download of all uploaded files
- ...
