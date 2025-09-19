import os

# WSGI application path
wsgi_app = os.environ.get("GUNICORN_WSGI", "app:app")

# Binding and workers
bind = os.environ.get("GUNICORN_BIND", "0.0.0.0:8000")

# Ensure a single worker in debug mode to avoid multiple workers racing over the same debug port
if os.environ.get("PY_DEBUGPY") == "1":
    workers = int(os.environ.get("GUNICORN_WORKERS", "1"))
else:
    workers = int(os.environ.get("GUNICORN_WORKERS", "1"))

# Logging
loglevel = os.environ.get("GUNICORN_LOGLEVEL", "debug" if os.environ.get("PY_DEBUGPY") == "1" else "info")
accesslog = os.environ.get("GUNICORN_ACCESSLOG", "-")
errorlog = os.environ.get("GUNICORN_ERRORLOG", "-")

# Timeouts — lengthen when debugging so breakpoints don't trigger worker timeouts
timeout = int(os.environ.get("GUNICORN_TIMEOUT", "3600" if os.environ.get("PY_DEBUGPY") == "1" else "30"))
graceful_timeout = int(os.environ.get("GUNICORN_GRACEFUL_TIMEOUT", "3600" if os.environ.get("PY_DEBUGPY") == "1" else "30"))
keepalive = int(os.environ.get("GUNICORN_KEEPALIVE", "120" if os.environ.get("PY_DEBUGPY") == "1" else "5"))


def post_fork(server, worker):
    """Start debugpy inside each worker after fork when enabled.

    This ensures the debugger attaches to the actual request-handling process
    in Gunicorn's prefork model, not just the master.
    """
    if os.environ.get("PY_DEBUGPY") != "1":
        return
    try:
        import debugpy
        raw = os.environ.get("DEBUGPY_PORT") or os.environ.get("PYTHON_DEBUGPY_PORT") or "5678"
        port = int(str(raw).strip())
        server.log.info("[debugpy] worker %s listening on 0.0.0.0:%s", worker.pid, port)
        debugpy.listen(("0.0.0.0", port))
        server.log.info("[debugpy] worker %s waiting for debugger to attach...", worker.pid)
        debugpy.wait_for_client()
    except Exception as exc:
        server.log.error("[debugpy] post_fork error in worker %s: %r", worker.pid, exc)

