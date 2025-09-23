    # Vulnerable demo for PHP backend under /php/split...
    # Regex: /php/split/((?<action>[^.]*)\.json)?$
    # Note: regex location cannot use proxy_pass with a URI. Rewrite first.
    location ~ ^/php/split/((?<action>[^.]*)\.json)?$ {
        set $loc "php-split";
        # Intentionally unsafe reflection into headers (demo only)
        add_header X-Action $action always;
        add_header X-Next $arg_next always;

        # Strip "/php/split/..." and keep only <action>
        rewrite ^/php/split/.*$ /public/$action break;
        proxy_set_header X-Action $action;
        proxy_set_header X-Next $arg_next;
        
        # Strip "/php" prefix so upstream sees "/split/..."
        # rewrite ^/php/(.*)$ /$1 break;
        proxy_pass http://backend-php:80;

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

    location /php/ {
        set $loc "php";
        proxy_pass http://backend-php:80/public/;  # default: forward to PHP public controller
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

    # Map /php1[...] to backend /public[...] without rewrite, using constant upstream
    location /php1 {
        set $loc "php1";
        proxy_pass http://backend-php:80/public/;
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
