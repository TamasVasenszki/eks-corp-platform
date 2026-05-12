#!/bin/bash

ALB_URL=$(kubectl get ingress eks-corp-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
BASE_URL="http://${ALB_URL}"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[TEST] $1${NC}"; }
section() { echo -e "\n${BLUE}══════════════════════════════${NC}\n${BLUE} $1${NC}\n${BLUE}══════════════════════════════${NC}"; }

section "Health Check"
log "GET /health"
curl -s $BASE_URL/health | jq

section "Authentication"
log "POST /auth/register"
curl -s -X POST $BASE_URL/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@ekscorp.com","password":"password123"}' | jq

log "POST /auth/login"
TOKEN=$(curl -s -X POST $BASE_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@ekscorp.com","password":"password123"}' | jq -r '.token')
echo "Token acquired: ${TOKEN:0:50}..."

section "Employees"
log "POST /employees - Create"
EMPLOYEE=$(curl -s -X POST $BASE_URL/employees \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name":"Jane Doe","email":"jane@ekscorp.com","department":"Engineering","position":"Developer"}' | jq)
echo $EMPLOYEE | jq
EMPLOYEE_ID=$(echo $EMPLOYEE | jq -r '.id')

if [ "$EMPLOYEE_ID" = "null" ] || [ -z "$EMPLOYEE_ID" ]; then
  log "Employee already exists, fetching existing..."
  EMPLOYEE_ID=$(curl -s $BASE_URL/employees \
    -H "Authorization: Bearer $TOKEN" | jq -r '.[0].id')
  log "Using employee ID: $EMPLOYEE_ID"
fi

log "GET /employees - List all"
curl -s $BASE_URL/employees \
  -H "Authorization: Bearer $TOKEN" | jq

log "GET /employees/:id - Get one"
curl -s $BASE_URL/employees/$EMPLOYEE_ID \
  -H "Authorization: Bearer $TOKEN" | jq

log "PUT /employees/:id - Update"
curl -s -X PUT $BASE_URL/employees/$EMPLOYEE_ID \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name":"John Doe","email":"john@ekscorp.com","department":"Engineering","position":"Senior Developer"}' | jq

section "Documents (S3)"
log "GET /documents/upload-url/:employeeId/:filename"
curl -s "$BASE_URL/documents/upload-url/$EMPLOYEE_ID/cv.pdf" \
  -H "Authorization: Bearer $TOKEN" | jq

log "GET /documents/download-url/:employeeId/:filename"
curl -s "$BASE_URL/documents/download-url/$EMPLOYEE_ID/cv.pdf" \
  -H "Authorization: Bearer $TOKEN" | jq

section "Done!"
echo "All endpoints tested successfully."