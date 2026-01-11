import logging
from http.server import SimpleHTTPRequestHandler, HTTPServer
import os
import shutil
import re
import json
import requests
import feedparser
import cgi

# =======================
# Logging Confirmation
# =======================
logger = logging.getLogger('server_logger')
logger.setLevel(logging.INFO)
#---Four Space Marker
ch = logging.StreamHandler()
ch.setLevel(logging.INFO)
#---Four Space Marker Check
formatter = logging.Formatter(
    '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
ch.setFormatter(formatter)
logger.addHandler(ch)
#---Four Space Marker

# =======================
# HTTP Request Handler
# =======================
class CustomHTTPRequestHandler(SimpleHTTPRequestHandler):

    # -------------------------
    # POST: File Upload
    # -------------------------
    def do_POST(self):
        try:
            ctype, pdict = cgi.parse_header(self.headers.get('Content-Type'))
#---Four Space Marker
            if ctype != 'multipart/form-data':
              self.send_response(400)
              self.end_headers()
              self.wfile.write(b'Invalid Content-Type')
              return
#---Four Space Marker
            form = cgi.FieldStorage(
                fp=self.rfile,
                headers=self.headers,
                environ=self.headers,
                keep_blank_values=True
            )  
#----------- Twelve Space Marker
            if 'file' not in form:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b'No file field found')
                return
#----------- Twelve Space Marker
            file_item = form['file']
            if not file_item.filename:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b'Empty filename')
                return
#----------- Twelve Space Marker
            filename = self.sanitize_filename(file_item.filename)
#----------- Twelve Space Marker            
            # Stage upload
            self.ensure_directory('uploads') # {^_^}LOOKFLAG=> USING upload(s)
            upload_path = os.path.join('uploads', filename)
#----------- Twelve Space Marker            
            with open(upload_path, 'wb') as f:
                f.write(file_item.file.read())
#----------- Twelve Space Marker
            # Route file based on prefix rules
            self.move_file(upload_path)
            
            logger.info(f'File uploaded and routed: {filename}')
#----------- Twelve Space Marker            
            # Success response
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
#----------- Twelve Space Marker -- HTML Section below --
            success_message = f"""
            <html>
            <head>
                <title>Upload Successful</title>
                <script>
                    function redirectToUpload() {{
                        window.location.href = '/upload';
                    }}
                </script>
            </head>
            <body style="text-align:center; background-color: black; color: green;">
                <h2>File Uploaded Successfully!</h2>
                <p>File: {filename}</p>
                <img src="/success.png" width="300"><br><br>
                <button onclick="redirectToUpload()"
                    style="font-size:18px; padding:10px; background-color:#34ac44;
                    color:white; border:none; border-radius:5px; cursor:pointer;">
                    ⬅ Upload Another File
                </button>
            </body>
            </html>
            """
#-----------|-- HTML Section above --> Pull Request from laptop -- code start below --|
            self.wfile.write(success_message.encode())

        except Exception as e:
            logger.error(f'Error during file upload: {e}')
            self.send_response(500)
            self.end_headers()
            self.wfile.write(b'Internal server error')

#---Four Space Marker
    # GET: Static + RSS
#---Four Space Marker --> do_GET Note: the success.png has no influance on the rss feed
    def do_GET(self):
        if self.path == '/success.png':
            self.serve_image('success.png')

        elif self.path == '/fetch_rss':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(self.fetch_rss_feed()).encode())

        else:
            super().do_GET()

    # -------------------------
    # RSS Feed
    # -------------------------
    def fetch_rss_feed(self):
        url = 'https://www.securityweek.com/feed/'
        headers = {'User-Agent': 'Mozilla/5.0'}

        try:
            response = requests.get(url, headers=headers, timeout=10)
            if response.status_code != 200:
                logger.error(f'RSS HTTP {response.status_code}')
                return []

            feed = feedparser.parse(response.content)
            return [
                {
                    'title': entry.title,
                    'link': entry.link,
                    'published': entry.published
                }
                for entry in feed.entries[:5]
            ]

        except Exception as e:
            logger.error(f'Error fetching RSS feed: {e}')
            return []

    # -------------------------
    # Helpers
    # -------------------------
    def serve_image(self, filename):
        if not os.path.exists(filename):
            self.send_response(404)
            self.end_headers()
            return

        with open(filename, 'rb') as f:
            self.send_response(200)
            self.send_header('Content-type', 'image/png')
            self.end_headers()
            self.wfile.write(f.read())

    def ensure_directory(self, directory):
        os.makedirs(directory, exist_ok=True)

    def sanitize_filename(self, filename):
        filename = os.path.basename(filename)
        if '..' in filename or filename.startswith('/'):
            return 'fake_passwd'
        return re.sub(r'[^a-zA-Z0-9._-]', '_', filename)

    # -------------------------
    # East Side Server File Rules
    # -------------------------
    def move_file(self, filepath):
        filename = os.path.basename(filepath).lower()

        if filename.startswith('orchid_'):
            self.move_orchid_files(filepath)
        elif filename.startswith('doc_'):
            self.move_doc_files(filepath)
        elif filename.startswith('after_'):
            self.move_afterwork_files(filepath)
        elif filename.startswith('assign_'):
            self.move_assignment_files(filepath)
        else:
            self.move_assignment_files(filepath)

    def move_orchid_files(self, filepath):
        self.ensure_directory('orchids')
        shutil.move(filepath, os.path.join('orchids', os.path.basename(filepath)))

    def move_doc_files(self, filepath):
        self.ensure_directory('docs')
        shutil.move(filepath, os.path.join('docs', os.path.basename(filepath)))

    def move_afterwork_files(self, filepath):
        self.ensure_directory('after-work')
        shutil.move(filepath, os.path.join('after-work', os.path.basename(filepath)))

    def move_assignment_files(self, filepath):
        self.ensure_directory('assignments')
        shutil.move(filepath, os.path.join('assignments', os.path.basename(filepath)))


# =========================
# Server Bootstrap
# =========================
def run(server_class=HTTPServer,
        handler_class=CustomHTTPRequestHandler,
        port=8000):
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    logger.info(f'Starting httpd on port {port}...')
    httpd.serve_forever()


if __name__ == '__main__':
    run()

