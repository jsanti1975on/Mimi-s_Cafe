## 💻 Agent Network Recon Demo – Empire + Starkiller

This demo shows a successful `ipconfig` command execution on a Windows 10 target using an active Empire agent session via Starkiller.

---

### 📌 Scenario Summary

- **Empire Agent ID**: `BBYDVHD6`  
- **Command Issued**: `shell ipconfig`  
- **Method**: Starkiller Web UI → Terminal tab  
- **Result**: Network configuration of the compromised host retrieved  
- **Host IP**: `172.20.10.110`  
- **Gateway**: `172.20.10.254`  
- **DNS**: `8.8.8.8`, `8.8.4.4`  
- **Interface**: Intel(R) 82574L Gigabit Network Connection  

---

### 📸 Screenshot

> Agent BBYDVHD6 successfully executes `ipconfig` from Empire via Starkiller:
<img width="1850" height="994" alt="image" src="https://github.com/user-attachments/assets/5518b1b7-23ba-4e71-b735-ab08747775c8" />

> Target
<img width="1246" height="969" alt="image" src="https://github.com/user-attachments/assets/b6bdaba2-685c-4ca6-8010-db9bb372408b" />

## 🔍 Empire C2 Traffic Analysis via Wireshark

The screenshot below captures network traffic between an Empire agent and the C2 server over **TCP port 80**.

<img width="1849" height="488" alt="ab826032-ef9c-4bbf-ba3d-6cb479c61756" src="https://github.com/user-attachments/assets/66424733-b614-4075-a27e-e3070a94bc4f" />


### 🖥 Empire C2 Server
- **IP Address:** `172.20.10.103`
- **Role:** Empire HTTP listener (stager + agent C2)

### 🎯 Target/Agent System
- **IP Address:** `185.125.190.17` *(or internal redirected traffic depending on setup)*
- **Role:** Empire stager/agent beaconing back to Empire server

---

### 🧠 Key Observations
- ✅ **TCP 3-Way Handshake** initiated from agent
- ✅ **HTTP GET** requests used for stager communication
- ⚠️ **TCP Retransmissions** and **Duplicate ACKs** present due to lab network conditions
- 🛠 Empire uses HTTP(S)-based agents which regularly beacon to the Empire listener

---

### 📄 Example Wireshark Filter Used

```wireshark
tcp.port == 80
```

> This filter isolates Empire’s default HTTP listener traffic to focus on agent communications.


# Empire Machine: Ping to DG - ok, Ping to target-win10 - false
<img width="1864" height="1029" alt="last-starkiller-image" src="https://github.com/user-attachments/assets/bbc0b5f3-2cdf-46b4-9dc2-e72ed7ff7a21" />

# Add more c2 content e.g. sliver  or continue with dvwa add ctf flags
