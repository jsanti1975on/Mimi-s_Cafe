# Add more detail configs and firewall settings of the ubuntu client used as a attack machine 

## Below is the directory of the *quik and dirty* file uploader.
- Binds to the proper nic
- Uses a config.ini to set the ip address

## Below is the directory layout.

```bash
http-upload-server/
├── uploads/                # [Runtime] Uploaded files saved here
├── index.html              # Upload form shown in the browser
├── server.py               # Main Python HTTP upload server
├── config.ini              # IP address, port, and upload path settings
└── README.md               # Documentation and usage instructions
```

