#!/bin/bash
# Usage:
#   ./test_api.sh --register [username] [password]
#   ./test_api.sh --login [username] [password]
#   ./test_api.sh --welcome <token>
#   ./test_api.sh --all [username] [password]

BASE_URL="http://localhost:8080"
DEFAULT_USERNAME="test_$(date +%s)"
DEFAULT_PASSWORD="password123"

show_help() {
  echo "Usage:"
  echo "  $0 --register [username] [password]"
  echo "  $0 --login [username] [password]"
  echo "  $0 --welcome <token>"
  echo "  $0 --all [username] [password]"
  exit 1
}

# Parse command
COMMAND="$1"
shift || true

case "$COMMAND" in
  --register)
    USERNAME="${1:-$DEFAULT_USERNAME}"
    PASSWORD="${2:-$DEFAULT_PASSWORD}"

    REGISTER_URL="$BASE_URL/register"
    response=$(curl -s -w "\n%{http_code}" -X POST "$REGISTER_URL" \
      -H "Content-Type: application/json" \
      -d "{\"username\":\"$USERNAME\", \"password\":\"$PASSWORD\"}")

    body=$(echo "$response" | sed '$d')
    code=$(echo "$response" | tail -n1)

    echo "=== Register ==="
    echo "POST $REGISTER_URL"
    echo "Response ($code): $body"

    if [ "$code" -eq 200 ]; then
      echo "✅ Registration successful for $USERNAME"
    elif [ "$code" -eq 400 ]; then
      echo "⚠️  User already exists: $USERNAME"
    else
      echo "❌ Registration failed ($code)"
      exit 1
    fi
    ;;

  --login)
    USERNAME="${1:-$DEFAULT_USERNAME}"
    PASSWORD="${2:-$DEFAULT_PASSWORD}"

    LOGIN_URL="$BASE_URL/login"
    response=$(curl -s -w "\n%{http_code}" -X POST "$LOGIN_URL" \
      -H "Content-Type: application/json" \
      -d "{\"username\":\"$USERNAME\", \"password\":\"$PASSWORD\"}")

    body=$(echo "$response" | sed '$d')
    code=$(echo "$response" | tail -n1)

    echo "=== Login ==="
    echo "POST $LOGIN_URL"
    echo "Response ($code): $body"

    if [ "$code" -eq 200 ]; then
      TOKEN=$(echo "$body" | grep -oP '"token":"\K[^"]+')
      echo "✅ Login successful, token: $TOKEN"
    else
      echo "❌ Login failed ($code)"
      exit 1
    fi
    ;;

  --welcome)
    TOKEN="$1"
    if [ -z "$TOKEN" ]; then
      echo "Error: Missing token"
      show_help
    fi

    WELCOME_URL="$BASE_URL/api/welcome"
    response=$(curl -s -w "\n%{http_code}" -X GET "$WELCOME_URL" \
      -H "Authorization: Bearer $TOKEN")

    body=$(echo "$response" | sed '$d')
    code=$(echo "$response" | tail -n1)

    echo "=== Welcome ==="
    echo "GET $WELCOME_URL"
    echo "Response ($code): $body"

    if [ "$code" -eq 200 ]; then
      echo "✅ Access granted"
    else
      echo "❌ Access denied ($code)"
      exit 1
    fi
    ;;

  --all)
    USERNAME="${1:-$DEFAULT_USERNAME}"
    PASSWORD="${2:-$DEFAULT_PASSWORD}"

    echo "Running full flow for $USERNAME..."
    "$0" --register "$USERNAME" "$PASSWORD"
    LOGIN_OUTPUT=$("$0" --login "$USERNAME" "$PASSWORD")
    echo "$LOGIN_OUTPUT"
    TOKEN=$(echo "$LOGIN_OUTPUT" | grep -oP '"token":"\K[^"]+')
    "$0" --welcome "$TOKEN"
    ;;

  *)
    show_help
    ;;
esac
