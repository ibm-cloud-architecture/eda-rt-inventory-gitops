curl -X 'POST' \
  'http://localhost:8080/api/stores/v1/start' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{ "backend": "KAFKA",
  "records": 100,
  "type": randomMax
}'
