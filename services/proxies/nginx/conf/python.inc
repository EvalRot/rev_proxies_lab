    # Vulnerable demo: reflects path capture and query param into headers
    # Regex: /py/split/((?<action>[^.]*)\.json)?$
    # Note: In regex locations proxy_pass MUST NOT contain a URI part.
    location ~ ^/py/split/((?<action>[^.]*)\.json)?$ {
        set $loc "split";
        # DANGEROUS: reflecting untrusted input into response and upstream headers
        add_header X-Action $action always;
        add_header X-Next $arg_next always;

        proxy_set_header X-Action $action;
        proxy_set_header X-Next $arg_next;

        # Rewrite to /public/<rest> then pass upstream without URI part
        rewrite ^/py/split/(.*)$ /public/$1 break;
        proxy_pass http://$py_host:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_set_header X-NGX-Request-URI $request_uri;
        proxy_set_header X-NGX-URI $uri;
        proxy_set_header X-NGX-Args $args;
        proxy_set_header Connection '';
        proxy_buffering off;
        proxy_request_buffering on;
        client_max_body_size 50m;
    }

    # Demo locations to show proxy_pass behavior
    # 1) Map /py1[...] to backend /public[...] without rewrite; use constant upstream for URI part passthrough
    location /py1 {
        set $loc "py1";
        proxy_pass http://backend-python:8000/public/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_set_header X-NGX-Request-URI $request_uri;
        proxy_set_header X-NGX-URI $uri;
        proxy_set_header X-NGX-Args $args;
        proxy_set_header Connection '';
        proxy_buffering off;
        proxy_request_buffering on;
        client_max_body_size 50m;
    }

    # 2) Replace /py2 with a simpler /py that forwards to backend root without rewrite
    location /py {
        set $loc "py";
        proxy_pass http://backend-python:8000/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_set_header X-NGX-Request-URI $request_uri;
        proxy_set_header X-NGX-URI $uri;
        proxy_set_header X-NGX-Args $args;
        proxy_set_header Connection '';
        proxy_buffering off;
        proxy_request_buffering on;
        client_max_body_size 50m;
    }

