import base64
import os
import logging
from flask import Flask, request, jsonify


app = Flask(__name__)
logging.basicConfig(level=os.environ.get("LOG_LEVEL", "INFO"))
logger = logging.getLogger("echo_backend")


@app.route("/", defaults={"path": ""}, methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS", "HEAD"])
@app.route("/<path:path>", methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS", "HEAD"])
def echo(path):
    body = request.get_data(cache=False)
    # log a concise line about the incoming request
    # Note: behind a proxy, remote_addr is the proxy IP; X-Forwarded-* headers carry client info
    logger.info("%s %s host=%s from=%s len=%s", request.method, request.full_path, request.host, request.remote_addr, len(body))
    payload = {
        "method": request.method,
        "url": request.url,
        "path": request.path,
        "full_path": request.full_path,
        "query_args": {k: v for k, v in request.args.lists()},
        "headers": list(request.headers.items()),  # note: duplicates may be merged by WSGI
        "remote_addr": request.remote_addr,
        "body_base64": base64.b64encode(body).decode("ascii"),
        "body_len": len(body),
        "content_length": request.content_length,
    }
    return jsonify(payload)


if __name__ == "__main__":
    host = os.environ.get("HOST", "0.0.0.0")
    port = int(os.environ.get("PORT", "8000"))
    app.run(host=host, port=port)
