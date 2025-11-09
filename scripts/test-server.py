#!/usr/bin/env python3
"""
Lightweight HTTP server used for Vegeta load tests.

Endpoints:
  GET /                    -> 200 OK, simple message
  GET /api/v1/health       -> 200 OK, JSON health response
"""

from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import signal
import sys
from typing import Tuple


HOST = "127.0.0.1"
PORT = 8080


class ReusableHTTPServer(HTTPServer):
    allow_reuse_address = True


class RequestHandler(BaseHTTPRequestHandler):
    server_version = "VegetaTestServer/1.0"

    def _send_plain(self, status: int, body: str, content_type: str = "text/plain") -> None:
        encoded = body.encode("utf-8")
        try:
            self.send_response(status)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(encoded)))
            self.end_headers()
            self.wfile.write(encoded)
        except (BrokenPipeError, ConnectionResetError):
            # Vegeta may close sockets aggressively; ignore broken pipes to keep CI clean.
            pass

    def do_GET(self) -> None:  # noqa: N802  # method name required by BaseHTTPRequestHandler
        if self.path == "/":
            self._send_plain(200, "Vegeta test server\n")
        elif self.path == "/api/v1/health":
            payload = {"status": "ok"}
            self._send_plain(200, json.dumps(payload) + "\n", "application/json")
        else:
            self._send_plain(404, "Not Found\n")

    def log_message(self, format: str, *args: Tuple[object, ...]) -> None:  # noqa: A003 - inherited name
        """Suppress default logging to keep CI output clean."""
        return


def main() -> None:
    httpd = ReusableHTTPServer((HOST, PORT), RequestHandler)

    def handle_signal(signum, frame):
        httpd.shutdown()
        sys.exit(0)

    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)

    print(f"Test server listening on http://{HOST}:{PORT}")
    httpd.serve_forever()


if __name__ == "__main__":
    main()

