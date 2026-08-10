# Rag on the Range
- Golden Template [x]

## RAG Cluster
- rag-winadmin []
- Stop logging point 11:54 pm 8-9-26

  <img width="1323" height="986" alt="image" src="https://github.com/user-attachments/assets/89a99747-1afc-4f88-9ef8-2a5df55353a4" />


## Next checkpoint: network identity
- Simple bash commands []

## Next Phase
- PROJECT AGENT TEXT BELOW

 ```bash
I want to build the host inventory collector before we start loading Windows Server Administration material into this machine.
 ```
### Below is the bash commands

```bash
echo "===== RAG NODE INVENTORY ====="
echo "Hostname: $(hostname)"
echo "FQDN: $(hostname -f)"
echo "IP:"
hostname -I
echo "MAC:"
ip -br link
echo "OS:"
grep PRETTY_NAME /etc/os-release
echo "VMware Tools:"
systemctl is-active open-vm-tools
echo "Docker:"
docker --version
echo "=============================="
```

### Work on the fqdn

<img width="398" height="349" alt="FQDN-IMAGE" src="https://github.com/user-attachments/assets/2d50693e-1d9d-4a98-be57-aa7dcdca23e4" />
