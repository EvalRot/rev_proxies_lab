#!/usr/bin/env python3
"""
Runner stub that reads a scenario YAML and composes the docker-compose invocation.

Requires pyyaml (`pip install pyyaml`). If it's not installed, the script
prints the equivalent docker compose command you can run via scripts/run.ps1.
"""
import argparse
import os
import subprocess
import sys


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("scenario", help="Path to scenario YAML, e.g. scenarios/nginx_python.yaml")
    ap.add_argument("--print", action="store_true", dest="print_only", help="Only print commands, don't execute")
    ap.add_argument("--port", type=int, default=8080)
    args = ap.parse_args()

    try:
        import yaml  # type: ignore
    except Exception:
        print("PyYAML not installed. Install with: pip install pyyaml", file=sys.stderr)
        print("Fallback: use scripts/run.ps1, e.g.:", file=sys.stderr)
        print("  pwsh scripts/run.ps1 -Action up -Proxy nginx -Backend python", file=sys.stderr)
        sys.exit(2)

    with open(args.scenario, "r", encoding="utf-8") as fh:
        data = yaml.safe_load(fh)

    chain = data.get("chain", [])
    backend = data.get("backend", "python")
    misconfigs = data.get("misconfigs", {})

    env = os.environ.copy()

    # For nginx, select config file
    if "nginx" in chain:
        variant = misconfigs.get("nginx", "base")
        if variant == "base":
            env["NGINX_CONF"] = os.path.join("services", "proxies", "nginx", "conf", "base.conf")
        else:
            env["NGINX_CONF"] = os.path.join("services", "proxies", "nginx", "conf", "misconfigs", f"{variant}.conf")
        env["NGINX_HOST_PORT"] = str(args.port)

    profiles = []
    profiles.extend(chain)
    if backend:
        profiles.append(backend)

    compose_cmd = [
        "docker", "compose",
        "-f", "compose/base.yml",
        "-f", "compose/proxies.yml",
        "-f", "compose/backends.yml",
    ]
    for p in profiles:
        compose_cmd.extend(["--profile", p])
    compose_cmd.extend(["up", "-d", "--build"])

    print("ENV overrides:")
    for k in [k for k in env.keys() if k.startswith("NGINX_")]:
        print(f"  {k}={env[k]}")
    print("Command:")
    print("  ", " ".join(compose_cmd))

    if not args.print_only:
        subprocess.check_call(compose_cmd, env=env)


if __name__ == "__main__":
    main()

