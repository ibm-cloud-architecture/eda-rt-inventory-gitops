curl -X 'POST' \
  'http://localhost:8080/api/stores/v1/startControlled' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{ "backend": "IBMMQ",
  "records": 1
}'
