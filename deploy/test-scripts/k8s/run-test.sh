#!/bin/bash

# User credential to register on app
email=example%40appsmith.com
password=$(openssl rand -base64 12)

# Get Ingress hostname
domain=$(kubectl get ingress appsmith-ingress -o json | jq -r '.status.loadBalancer.ingress[0].hostname')

# Check Backend API
status_code=$(curl -s -o /dev/null -I -w "%{http_code}" http://$domain/api/v1 || true)

# Create account
status_code_register=$(curl -X POST --write-out %{http_code} --silent --output /dev/null http://$domain/api/v1/users \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "Referer: http://$domain/user/signup" \
    --data-raw "email=$email&password=$password")

# Login
status_code_login=$(curl -X POST --write-out %{http_code} --silent --output /dev/null "http://$domain/api/v1/login" \
    -H "Referer: http://$domain/user/login" \
    --data-raw "username=$email&password=$password")

count_fail=0
if [[ $status_code -eq 401 ]]; then
    echo "Api backend succeeded, status code: $status_code"
else
    echo "Api backend failed, status code: $status_code"
    count_fail=$((count_fail + 1))
fi

if [[ $status_code_register -eq 302 ]]; then
    echo "Register succeeded, status code: $status_code_register"
else
    echo "Register failed, status code: $status_code_register"
    count_fail=$((count_fail + 1))
fi

if [[ $status_code_login -eq 302 ]]; then
    echo "Login succeeded, status code: $status_code_login"
else
    echo "Login failed, status code: $status_code_login"
    count_fail=$((count_fail + 1))
fi

if [[ $count_fail -eq 0 ]]; then
    echo "SUCCEEDED!!!"
    exit 0
else
    echo "FAILED!!!"
    exit 1
fi
