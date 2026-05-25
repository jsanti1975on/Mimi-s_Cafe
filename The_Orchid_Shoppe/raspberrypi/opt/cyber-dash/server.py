#!/usr/bin/env python3
import os
from http.server import HTTPServer, SimpleHTTPRequestHandler
from email.parser import BytesParser
from email.policy import default
# This block replaces any server.py that used cgi
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
UPLOAD_DIR = os.path.join(BASE_DIR, "..", "uploads")

class UploadHandler(SimpleHTTPRequestHandler):

    def do_POST(self):
        if self.path != "/upload":
            self.send_error(404)
            return

        content_length = int(self.headers.get('Content-Length', 0))
        content_type = self.headers.get('Content-Type')

        if not content_type or 'multipart/form-data' not in content_type:
            self.send_error(400, "Invalid Content-Type")
            return

        body = self.rfile.read(content_length)

        msg = BytesParser(policy=default).parsebytes(
            b'Content-Type: ' + content_type.encode() + b'\r\n\r\n' + body
        )

        os.makedirs(UPLOAD_DIR, exist_ok=True)

        uploaded = False

        for part in msg.iter_parts():
            if part.get_content_disposition() == 'form-data':
                filename = part.get_filename()

                if filename:
                    safe_name = os.path.basename(filename)
                    filepath = os.path.join(UPLOAD_DIR, safe_name)

                    payload = part.get_payload(decode=True)

                    if isinstance(payload, str):
                        payload = payload.encode()

                    with open(filepath, 'wb') as f:
                        f.write(payload)

                    print(f"[+] Uploaded: {safe_name}")
                    uploaded = True

        if uploaded:
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"OK: File uploaded")
        else:
            self.send_error(400, "No file found")

def run():
    os.makedirs(UPLOAD_DIR, exist_ok=True)

    server_address = ("0.0.0.0", XXXX)
    httpd = HTTPServer(server_address, UploadHandler)

    print("Cyber Dash Upload Server running on port XXXX")
    print(f"[+] Upload dir: {UPLOAD_DIR}")

    httpd.serve_forever()

if __name__ == '__main__':
    run()
