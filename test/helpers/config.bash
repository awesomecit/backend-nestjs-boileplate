#!/bin/bash

# Load environment variables from .env file
if [ -f "$(dirname "$0")/../../.env" ]; then
    set -a
    source "$(dirname "$0")/../../.env"
    set +a
fi

# Set default values if environment variables are not set
export PROMETHEUS_PORT="${PROMETHEUS_PORT:-9090}"
export PROMETHEUS_HOST="${PROMETHEUS_HOST:-localhost}"
export PROMETHEUS_URL="http://${PROMETHEUS_HOST}:${PROMETHEUS_PORT}"

export GRAFANA_PORT="${GRAFANA_PORT:-3000}"
export GRAFANA_HOST="${GRAFANA_HOST:-localhost}"
export GRAFANA_URL="http://${GRAFANA_HOST}:${GRAFANA_PORT}"
export GRAFANA_ADMIN_USER="${GRAFANA_ADMIN_USER:-admin}"
export GRAFANA_ADMIN_PASSWORD="${GRAFANA_ADMIN_PASSWORD:-admin123}"

export NODE_EXPORTER_PORT="${NODE_EXPORTER_PORT:-9100}"
export NODE_EXPORTER_HOST="${NODE_EXPORTER_HOST:-localhost}"
export NODE_EXPORTER_URL="http://${NODE_EXPORTER_HOST}:${NODE_EXPORTER_PORT}"

export NGINX_EXPORTER_PORT="${NGINX_EXPORTER_PORT:-9113}"
export NGINX_EXPORTER_HOST="${NGINX_EXPORTER_HOST:-localhost}"
export NGINX_EXPORTER_URL="http://${NGINX_EXPORTER_HOST}:${NGINX_EXPORTER_PORT}"

export PORTAINER_PORT="${PORTAINER_PORT:-9000}"
export PORTAINER_HOST="${PORTAINER_HOST:-localhost}"
export PORTAINER_URL="http://${PORTAINER_HOST}:${PORTAINER_PORT}"

export NGINX_PORT="${NGINX_PORT:-80}"
export NGINX_HOST="${NGINX_HOST:-localhost}"
export NGINX_URL="http://${NGINX_HOST}:${NGINX_PORT}"

export APP_PORT="${APP_PORT:-3000}"
export APP_HOST="${APP_HOST:-localhost}"
export APP_URL="http://${APP_HOST}:${APP_PORT}"

export DOCKER_STACK_NAME="${DOCKER_STACK_NAME:-monitoring}"
export BATS_TEST_TIMEOUT="${BATS_TEST_TIMEOUT:-120}"

# Helper function to get URL for a service
get_service_url() {
    local service_name="$1"
    case "$service_name" in
        prometheus) echo "$PROMETHEUS_URL" ;;
        grafana) echo "$GRAFANA_URL" ;;
        node-exporter) echo "$NODE_EXPORTER_URL" ;;
        nginx-exporter) echo "$NGINX_EXPORTER_URL" ;;
        portainer) echo "$PORTAINER_URL" ;;
        nginx) echo "$NGINX_URL" ;;
        app) echo "$APP_URL" ;;
        *) echo "http://localhost:8080" ;;
    esac
}

# Helper function to get port for a service
get_service_port() {
    local service_name="$1"
    case "$service_name" in
        prometheus) echo "$PROMETHEUS_PORT" ;;
        grafana) echo "$GRAFANA_PORT" ;;
        node-exporter) echo "$NODE_EXPORTER_PORT" ;;
        nginx-exporter) echo "$NGINX_EXPORTER_PORT" ;;
        portainer) echo "$PORTAINER_PORT" ;;
        nginx) echo "$NGINX_PORT" ;;
        app) echo "$APP_PORT" ;;
        *) echo "8080" ;;
    esac
}
