#!/bin/bash

docker compose up --build -d

sleep 5

response=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"prompt": "a serene landscape", "numImages": 1}' \
  http://localhost:8080/generate-images)

echo "Response from server: $response"

docker compose down
