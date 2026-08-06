#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  Run the site locally, exactly as GitHub Pages will serve it.
#
#      ./serve.sh            # http://localhost:8000
#      ./serve.sh 3000       # pick another port
#
#  Edit a file, save, hit reload — that's the whole loop. Responses are sent
#  with no-cache headers so the browser never shows you a stale stylesheet.
#  Ctrl-C to stop.
#
#  Needs nothing but python3. No npm, no build step.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"

# deploy.conf is optional here — serving is local and needs no credentials.
PORT="${1:-}"
if [ -z "$PORT" ] && [ -f "$ROOT/deploy.conf" ]; then
  PORT="$(sed -n 's/^[[:space:]]*PORT=["'"'"']\?\([0-9]\+\).*/\1/p' "$ROOT/deploy.conf" | tail -1)"
fi
PORT="${PORT:-8000}"

command -v python3 >/dev/null 2>&1 || {
  echo "python3 not found. Install it, or use any static server:" >&2
  echo "  npx serve .      /      php -S localhost:$PORT" >&2
  exit 1
}

URL="http://localhost:$PORT"

printf '\033[32m==>\033[0m \033[1mServing %s\033[0m\n' "$ROOT"
printf '    %s\n' "$URL"
printf '    %s/resume.html   (Ctrl-P to check the print layout)\n' "$URL"
printf '\033[2m    Ctrl-C to stop\033[0m\n\n'

# Open a browser once the socket is actually listening.
( for _ in $(seq 1 40); do
    if (exec 3<>/dev/tcp/127.0.0.1/"$PORT") 2>/dev/null; then
      for opener in xdg-open open; do
        command -v "$opener" >/dev/null 2>&1 && { "$opener" "$URL" >/dev/null 2>&1; break; }
      done
      break
    fi
    sleep 0.25
  done ) &

exec python3 - "$PORT" "$ROOT" <<'PY'
import functools, sys, http.server, socketserver

port, root = int(sys.argv[1]), sys.argv[2]

class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # Always hand back fresh files while developing.
        self.send_header("Cache-Control", "no-store, must-revalidate")
        self.send_header("Pragma", "no-cache")
        super().end_headers()

    def log_message(self, fmt, *args):
        sys.stderr.write("    %s\n" % (fmt % args))

class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True

try:
    with Server(("127.0.0.1", port), functools.partial(Handler, directory=root)) as httpd:
        httpd.serve_forever()
except OSError as e:
    sys.exit("\n  Port %d is busy (%s). Try:  ./serve.sh %d\n" % (port, e.strerror, port + 1))
except KeyboardInterrupt:
    sys.exit("\n  stopped\n")
PY
