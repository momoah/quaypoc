export QUAY=/data/quayroot

# Create dedicated network so containers can access container names (no DNS)
podman network create quay-net

# Postgres DB
mkdir -p $QUAY/postgres-quay
setfacl -m u:26:-wx $QUAY/postgres-quay

podman run -d --net quay-net --name postgresql-quay \
--restart=always \
-e POSTGRESQL_USER=quayuser \
-e POSTGRESQL_PASSWORD=quaypass \
-e POSTGRESQL_DATABASE=quay \
-e POSTGRESQL_ADMIN_PASSWORD=adminpass \
-e POSTGRESQL_MAX_CONNECTIONS=100 \
-p 5432:5432 \
-v $QUAY/postgres-quay:/var/lib/pgsql/data:Z \
registry.redhat.io/rhel8/postgresql-13
podman exec -it postgresql-quay /bin/bash -c 'echo "CREATE EXTENSION IF NOT EXISTS pg_trgm" | psql -d quay -U postgres'
# https://access.redhat.com/solutions/7011418
QUAY_POSTGRES=`podman ps | grep postgres | awk '{print $1}'`
podman exec -it $QUAY_POSTGRES psql -d quay -c "UPDATE "public.user" SET invalid_login_attempts = 0 WHERE username = 'quayadmin'"

# REDIS

podman run -d --net quay-net --name redis \
--restart=always \
-p 6379:6379 \
-e REDIS_PASSWORD=strongpassword \
registry.redhat.io/rhel8/redis-6:1-110

# CONFIG_DIR
mkdir -p $QUAY/config
chmod -R +r $QUAY/config
cp config.yaml $QUAY/config/

# Quay Registry

mkdir -p $QUAY/storage
setfacl -m u:1001:-wx $QUAY/storage

podman run -d --net quay-net -p 80:8080 -p 443:8443 \
--restart=always \
--name=quay \
-v $QUAY/config:/conf/stack:Z \
-v $QUAY/storage:/datastorage:Z \
registry.redhat.io/quay/quay-rhel8:v3.15.1


