<?php
header('Content-Type: application/json; charset=utf-8');

$headers = [];
foreach (getallheaders() as $k => $v) {
    $headers[] = [$k, $v];
}

$body = file_get_contents('php://input');
$path = isset($_GET['path']) ? $_GET['path'] : '';

@error_log(sprintf(
    'php_internal method=%s uri="%s" host=%s from=%s len=%d path="%s"',
    $_SERVER['REQUEST_METHOD'] ?? '-',
    $_SERVER['REQUEST_URI'] ?? '-',
    $_SERVER['HTTP_HOST'] ?? '-',
    $_SERVER['REMOTE_ADDR'] ?? '-',
    strlen($body),
    $path
));

$payload = [
    'scope' => 'internal',
    'method' => $_SERVER['REQUEST_METHOD'] ?? null,
    'request_uri' => $_SERVER['REQUEST_URI'] ?? null,
    'raw_query_string' => $_SERVER['QUERY_STRING'] ?? null,
    'path_param' => $path,
    'headers' => $headers,
    'remote_addr' => $_SERVER['REMOTE_ADDR'] ?? null,
    'body_base64' => base64_encode($body),
    'body_len' => strlen($body),
];

echo json_encode($payload, JSON_UNESCAPED_SLASHES);
