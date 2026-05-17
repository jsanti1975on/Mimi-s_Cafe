# HTTPS Reverse Proxy Deployment – Ubuntu GUI East Side Server

## Overview

The East Side Server dashboard environment was successfully migrated behind a secure HTTPS reverse proxy using Apache on Ubuntu Server.

This upgrade replaced direct HTTP access to the Python application with enterprise-style TLS termination using Apache and an internal Microsoft Active Directory Certificate Services (AD CS) certificate.

---

# Infrastructure Changes

## Previous Architecture

```text
Client Browser
    │
HTTP :8081
    ▼
Python server.py
```
<img width="1929" height="1039" alt="Image14" src="https://github.com/user-attachments/assets/f4be1fbd-a4fa-48bb-9c2d-2eaea6462b3c" />
