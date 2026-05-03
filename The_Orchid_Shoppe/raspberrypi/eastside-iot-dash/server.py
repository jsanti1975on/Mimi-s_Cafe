import logging
from http.server import SimpleHTTPRequestHandler, HTTPServer
import os
import shutil
import re
import json
import requests
import feedparser  # why: RSS parsing (XML)

# =========================
# Routing Config
# =========================
ROUTES = {
    "orchid_": "orchids",
    "doc_": "docs",
    "after_": "after-work",
    "assign_": "assignments",
}

DEFAULT_ROUTE = "assignments"


def resolve_destination(filename: str) -> str:
    for prefix, folder in ROUTES.items():
        if filename.startswith(prefix):
            return folder
    return DEFAULT_ROUTE


def get_unique_path(directory: str, filename: str) -> str:
    base, ext = os.path.splitext(filename)
    counter = 1
    path = os.path.join(directory, filename)

    while os.path.exists(path):
        path = os.path.join(directory, f"{base}_{counter}{ext}")
        counter += 1  # why: avoid overwrite loop

    return path


def move_file(filepath: str):
    filename = os.path.basename(filepath).lower()
    destination_folder = resolve_destination(filename)

    os.makedirs(destination_folder, exist_ok=True)
    final_path = get_unique_path(destination_folder, filename)

    shutil.move(filepath, final_path)
    return final_path


# =========================
# Logging
# =========================
logger = logging.getLogger('server_logger')
logger.setLevel(logging.INFO)

ch = logging.StreamHandler()
ch.setLevel(logging.INFO)

formatter = logging.Formatter(
    '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
ch.setFormatter(formatter)
logger.addHandler(ch)


# =========================
# HTTP Handler
# =========================
class CustomHTTPRequestHandler(SimpleHTTPRequestHandler):

    def do_POST(self):
        try:
            content_type = self.headers.get('Content-Type')
            if not content_type or 'multipart/form-data' not in content_type:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b'Invalid Content-Type')
                return

            if "boundary=" not in content_type:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b'Missing boundary')
                return

            boundary = content_type.split("boundary=")[1].strip().encode()

            content_length = int(self.headers.get('Content-Length', 0))
            if content_length == 0:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b'Empty body')
                return

            body = self.rfile.read(content_length)
            parts = body.split(b'--' + boundary)

            file_data = None
            filename = None

            for part in parts:
                if b'Content-Disposition' in part and b'name="file"' in part:
                    try:
                        headers, file_content = part.split(b'\r\n\r\n', 1)
                    except ValueError:
                        continue  # why: skip malformed parts

                    file_content = file_content.rstrip(b'\r\n--')

                    disposition = headers.decode(errors='ignore')
                    match = re.search(r'filename="(.+?)"', disposition)

                    if match:
                        filename = self.sanitize_filename(match.group(1))
                        file_data = file_content
                        break

            if not file_data or not filename:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b'No valid file uploaded')
                return

            self.ensure_directory('uploads')
            upload_path = os.path.join('uploads', filename)

            with open(upload_path, 'wb') as f:
                f.write(file_data)

            final_path = move_file(upload_path)

            logger.info(f'File uploaded and routed: {filename} -> {final_path}')

            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()

            self.wfile.write(f"""
                <html>
                <body style="text-align:center;background:black;color:green;">
                    <h2>Upload Success</h2>
                    <p>{filename}</p>
                    <img src="/success.png" width="300"><br><br>
                    <a href="/">Back</a>
                </body>
                </html>
            """.encode())

        except Exception as e:
            logger.error(f'Upload error: {e}')
            self.send_response(500)
            self.end_headers()

    def do_GET(self):
        if self.path == '/fetch_rss':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(self.fetch_rss_feed()).encode())
        else:
            super().do_GET()

    def fetch_rss_feed(self):
        url = 'https://www.securityweek.com/feed/'
        try:
            response = requests.get(url, timeout=10)
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
            logger.error(f'RSS error: {e}')
            return []

    def ensure_directory(self, directory):
        os.makedirs(directory, exist_ok=True)

    def sanitize_filename(self, filename):
        filename = os.path.basename(filename)
        return re.sub(r'[^a-zA-Z0-9._-]', '_', filename)


# =========================
# Server
# =========================
def run(server_class=HTTPServer,
        handler_class=CustomHTTPRequestHandler,
        port=8888):
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    logger.info(f'Starting httpd on port {port}...')
    httpd.serve_forever()


if __name__ == '__main__':
    run()
