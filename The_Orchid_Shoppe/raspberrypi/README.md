## 🔄 Update: Removed Deprecated `cgi` Module

The server.py code block has been updated to remove the deprecated `cgi` module, which is scheduled for removal in Python 3.13.

### ✅ What Changed
- Replaced `cgi.FieldStorage` with a custom multipart/form-data parser
- Implemented manual boundary parsing from HTTP headers
- Directly processed raw request body (`rfile.read`) for file extraction

### 🎯 Why This Matters
- Ensures compatibility with future Python versions
- Removes reliance on deprecated standard library components
- Provides more control over upload handling and validation

### ⚙️ Result
File uploads and routing behavior remain unchanged, but the implementation is now **future-proof, lightweight, and fully standard-library compliant**.

### Note to future me!
- !!!{^_^}LOOKFLAG=> This server.py is for the IoT room.
- The update is for the IoT dash not the very first server.py in 2024.
- Update or remove those old pdf's and even the Kali Purple box is gone - NOW!!! using Hyper-v as jump server mainly for (PowerShell) use.
