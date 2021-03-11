#!/bin/bash

#
# create file "config" with similar parameters
# HOST=11.11.11.11
# PASS=%YOUR_SECRET_PASSWORD%
# MAILTO=aaa@bbb.cc,bbb@bbb.cc
#

HOST=$(grep HOST config | cut -d= -f2)
PASS=$(grep PASS config | cut -d= -f2)
MAILTO=$(grep MAILTO config | cut -d= -f2)

VER=$(pgrep -fa pgsql | awk '{print $(NF-2) }' | awk -F "/" '{ print $3 }' | awk -F "-" '{ print $2 }')

if [ -f /etc/systemctl/system/postgresql-"$VER".service.d/environment.conf ]; then
    PGPATH=$(grep -e '^Environment=PGDATA' /etc/systemd/system/postgresql-"$VER".service.d/environment.conf | cut -d= -f3)
else
    PGPATH=$(grep -e '^Environment=PGDATA' /usr/lib/systemd/system/postgresql-"$VER".service | cut -d= -f3)
fi

PORT=$(grep -e '^port' "$PGPATH"/postgresql.conf | awk '{ print $3}' )
USER=$(grep -e '^User' /usr/lib/systemd/system/postgresql-"$VER".service | cut -d= -f2)

mkdir -p "$(pwd)"/log
echo "$HOSTNAME" > "$(pwd)"/log/vacuum.log
date >> "$(pwd)"/log/vacuum.log
echo "begin vacuum" >> "$(pwd)"/log/vacuum.log
PGPASSWORD="$PASS" vacuumdb --host="$HOST" --port="$PORT" --username="$USER" -a -z -F -j4
date >> "$(pwd)"/log/vacuum.log
echo "end vacuum" >> "$(pwd)"/log/vacuum.log
mail -s 'Service "VACUUM PostgreSQL"' "$MAILTO" < "$(pwd)"/log/vacuum.log
