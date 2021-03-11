#!/bin/bash

# this script moves PGDATA variable to external file

VER=$(pgrep -fa pgsql | awk '{print $(NF-2) }' | awk -F "/" '{ print $3 }' | awk -F "-" '{ print $2 }')
PGPATH=$(grep -e '^Environment=PGDATA' /usr/lib/systemd/system/postgresql-"$VER".service | cut -d= -f3)

mkdir -p /etc/systemd/system/postgresql-"$VER".service.d
touch /etc/systemd/system/postgresql-"$VER".service.d/environment.conf

echo "[Service]
Environment=PGDATA=$PGPATH" > /etc/systemd/system/postgresql-"$VER".service.d/environment.conf

systemctl daemon-reload
systemctl restart postgresql-"$VER".service
