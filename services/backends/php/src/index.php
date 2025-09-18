<?php
header('Content-Type: application/json; charset=utf-8');

// Capture server/environment details similar to the Python echo
$headers = [];
foreach (getallheaders() as $k => $v) {
    $headers[] = [$k, $v];
}

$body = file_get_contents('php://input');

// Log one concise line per request to stderr (captured by Docker logs)
@error_log(sprintf(
    'php_backend method=%s uri="%s" host=%s from=%s len=%d',
    $_SERVER['REQUEST_METHOD'] ?? '-',
    $_SERVER['REQUEST_URI'] ?? '-',
    $_SERVER['HTTP_HOST'] ?? '-',
    $_SERVER['REMOTE_ADDR'] ?? '-',
    strlen($body)
));

$payload = [
    'scope' => 'php-public',
    'method' => $_SERVER['REQUEST_METHOD'] ?? null,
    'request_uri' => $_SERVER['REQUEST_URI'] ?? null,
    'raw_query_string' => $_SERVER['QUERY_STRING'] ?? null,
    'path_info' => $_SERVER['PATH_INFO'] ?? null,
    'headers' => $headers,
    'remote_addr' => $_SERVER['REMOTE_ADDR'] ?? null,
    'body_base64' => base64_encode($body),
    'body_len' => strlen($body),
];

echo json_encode($payload, JSON_UNESCAPED_SLASHES);
