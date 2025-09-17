import base64
import os
import logging
from flask import Flask, request, jsonify


app = Flask(__name__)
logging.basicConfig(level=os.environ.get("LOG_LEVEL", "INFO"))
logger = logging.getLogger("echo_backend")


def _echo_payload(scope: str):
    body = request.get_data(cache=False)
    raw_uri = request.environ.get("RAW_URI") or request.environ.get("REQUEST_URI")
    # Log both raw URI (as received by WSGI server) and Flask-decoded full_path
    logger.info(
        "%s raw=\"%s\" decoded=\"%s\" host=%s from=%s len=%s scope=%s",
        request.method,
        raw_uri,
        request.full_path,
        request.host,
        request.remote_addr,
        len(body),
        scope,
    )
    return {
        "scope": scope,
        "method": request.method,
        "url": request.url,
        "path": request.path,
        "full_path": request.full_path,
        "raw_uri": raw_uri,
        "query_string_raw": request.query_string.decode("latin1", "replace"),
        "query_args": {k: v for k, v in request.args.lists()},
        "headers": list(request.headers.items()),
        "remote_addr": request.remote_addr,
        "body_base64": base64.b64encode(body).decode("ascii"),
        "body_len": len(body),
        "content_length": request.content_length,
    }


@app.route("/public", defaults={"path": ""}, methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS", "HEAD"])
@app.route("/public/<path:path>", methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS", "HEAD"])
def public(path):
    return jsonify(_echo_payload("public"))


@app.route("/internal", defaults={"path": ""}, methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS", "HEAD"])
@app.route("/internal/<path:path>", methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS", "HEAD"])
def internal(path):
    # Intentionally accessible if request reaches it; Nginx config is expected to route only to /public
    return jsonify(_echo_payload("internal"))


if __name__ == "__main__":
    host = os.environ.get("HOST", "0.0.0.0")
    port = int(os.environ.get("PORT", "8000"))
    app.run(host=host, port=port)
