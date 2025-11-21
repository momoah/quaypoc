#!/bin/bash
# A script to start containerised Quay after a shutdown or a reboot (avoiding systemd here).

export QUAY=/data/quayroot

# --- Cleanup Function ---
cleanup_containers() {
    echo "Attempting to stop and remove existing containers..."
    local containers=("quay" "postgresql-quay" "redis")
    for name in "${containers[@]}"; do
        if podman ps -a --format '{{.Names}}' | grep -q "^$name\$"; then
            echo "Stopping and removing container: $name"
            # Use 'stop' then 'rm' to ensure a clean removal
            podman stop -t 5 "$name" > /dev/null 2>&1
            podman rm "$name" > /dev/null 2>&1
        else
            echo "Container $name not found, skipping removal."
        fi
    done
    echo "Cleanup complete."
}

# --- Execute Cleanup before starting new containers ---
cleanup_containers

# --- ensure network is present ---- 
podman network create quay-net


# --- 1. Postgres DB Setup ---
echo "Starting PostgreSQL container..."
mkdir -p $QUAY/postgres-quay
setfacl -m u:26:-wx $QUAY/postgres-quay

podman run -d --name postgresql-quay \
--authfile /data/registry.redhat.io.auth.json \
--restart=always \
--net quay-net \
-e POSTGRESQL_USER=quayuser \
-e POSTGRESQL_PASSWORD=quaypass \
-e POSTGRESQL_DATABASE=quay \
-e POSTGRESQL_ADMIN_PASSWORD=adminpass \
-e POSTGRESQL_MAX_CONNECTIONS=4096 \
-p 5432:5432 \
-v $QUAY/postgres-quay:/var/lib/pgsql/data:Z \
registry.redhat.io/rhel8/postgresql-13

echo "Waiting 10 seconds for PostgreSQL to initialize..."
sleep 10 

echo "Configuring PostgreSQL extensions..."
# Create pg_trgm extension
podman exec -it postgresql-quay /bin/bash -c 'echo "CREATE EXTENSION IF NOT EXISTS pg_trgm" | psql -d quay -U postgres'

# NOTE: The Quay schema (including the "public.user" table) does not exist yet.
# The command to reset invalid login attempts is removed here, as it requires
# Quay to have initialized the DB first.

# --- 2. REDIS Setup ---
echo "Starting Redis container..."
podman run -d --name redis \
--net quay-net \
--authfile /data/registry.redhat.io.auth.json \
--restart=always \
-p 6379:6379 \
-e REDIS_PASSWORD=strongpassword \
registry.redhat.io/rhel8/redis-6:1-110

# --- 3. Quay Registry Setup ---
echo "Starting Quay Registry container..."

# CONFIG_DIR setup
mkdir -p $QUAY/config
chmod -R +r $QUAY/config
if [ ! -f config.yaml ]; then
    echo "ERROR: config.yaml not found in the current directory."
    exit 1
fi
cp config.yaml $QUAY/config/

# Storage setup
mkdir -p $QUAY/storage
setfacl -m u:1001:-wx $QUAY/storage

# Start Quay
podman run -d -p 80:8080 -p 443:8443 \
--net quay-net \
--authfile /data/registry.redhat.io.auth.json \
--restart=always \
--name=quay \
-v $QUAY/config:/conf/stack:Z \
-v $QUAY/storage:/datastorage:Z \
registry.redhat.io/quay/quay-rhel8:v3.15.2

echo "Quay setup script complete. Check container status with: podman ps"

