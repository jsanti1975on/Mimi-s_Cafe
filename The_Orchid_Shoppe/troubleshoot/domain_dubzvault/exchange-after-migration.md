# ✅ Exchange OWA Recovery — Successful Validation

## 📍 Outcome

After troubleshooting and remediation, **Outlook Web App (OWA)** is fully operational:

- 🌐 URL: `https://mail.dubz-vault.corp/owa`
- 🔐 Authentication: ✅ Successful
- 📬 Mailbox Access: ✅ Confirmed
- 📎 Attachments: ✅ Accessible and downloadable

---

## 🔍 What Was Validated

- User login session established successfully
- Mailbox content loads without error
- Email preview and reading pane functioning
- Attachment handling working (test file opened/downloaded)
- HTTPS access stable over FortiGate VLAN routing

---

## 🛠️ Key Fixes Applied

- Removed conflicting IIS binding:
```bash
https 127.0.0.1:443
```
- Ensured correct binding:
```bash
https *:443 mail.dubz-vault.corp
```
- Restarted IIS (`iisreset`)
- Recovered Exchange AD Topology service (via reboot)

---

## 🧠 Technical Takeaway

This issue was not network-related, but rather a **multi-layer service disruption** involving:

- IIS binding conflicts
- Exchange virtual directory routing
- Active Directory service dependency (Topology service)

---

## 🚀 Status

✔ Exchange Web Services: Operational  
✔ OWA: Fully functional  
✔ Client Access: Verified  

---

## 📌 Next Step

Implement **Internal Certificate Authority (AD CS)** to:
- Eliminate browser trust warnings
- Standardize certificate lifecycle
- Support additional services (ECP, EWS, Autodiscover)

---
<img width="1934" height="1094" alt="Exchange-After-Migration-FortiGate" src="https://github.com/user-attachments/assets/cb5f62fb-31c5-4cef-a11b-b013324a2505" />
