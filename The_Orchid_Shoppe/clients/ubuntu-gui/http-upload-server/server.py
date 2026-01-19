#!/usr/bin/env python3

import os
from http.server import HTTPServer, SimpleHTTPRequestHandler
import cgi
import configparser

# --- Load configuration ---
config = configparser.ConfigParser()
config.read('config.ini')

IP = config['server'].get('ip', '0.0.0.0')
PORT = config['server'].getint('port', 8080)
UPLOAD_DIR = config['server'].get('upload_dir', 'uploads')


# --- Upload Handler ---
class UploadHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            self.path = '/index.html'
        return SimpleHTTPRequestHandler.do_GET(self)

    def do_POST(self):
        if self.path == '/upload':
            ctype, pdict = cgi.parse_header(self.headers['Content-Type'])
            if ctype == 'multipart/form-data':
                form = cgi.FieldStorage(fp=self.rfile,
                                        headers=self.headers,
                                        environ={'REQUEST_METHOD': 'POST'})
                if 'file' in form:
                    file_item = form['file']
                    filename = os.path.basename(file_item.filename)
                    os.makedirs(UPLOAD_DIR, exist_ok=True)
                    filepath = os.path.join(UPLOAD_DIR, filename)
                    
                    with open(filepath, 'wb') as f:
                        f.write(file_item.file.read())

                    self.send_response(200)
                    self.end_headers()
                    self.wfile.write(f"<h2>✅ File uploaded: {filename}</h2>".encode())
                    return
        self.send_response(400)
        self.end_headers()
        self.wfile.write(b"❌ Upload failed")


# --- Start Server ---
if __name__ == "__main__":
    os.makedirs(UPLOAD_DIR, exist_ok=True)
    server_address = (IP, PORT)
    httpd = HTTPServer(server_address, UploadHandler)
    print(f"🚀 Serving HTTP on {IP} port {PORT} (Upload Dir: {UPLOAD_DIR})")
    httpd.serve_forever()
