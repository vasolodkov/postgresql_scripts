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
DB=$(PGPASSWORD="$PASS" psql --port="$PORT" --username="$USER" -w --command "SELECT datname FROM pg_database;" | tail -n +3 | head -n -2 | grep -E -v "template0|template1|postgres" | cut -c2-)

mkdir -p "$(pwd)"/log
echo "$DB" > "$(pwd)"/log/analyze.log
date >> "$(pwd)"/log/analyze.log
echo "begin analyze" >> "$(pwd)"/log/analyze.log
for I in ${DB}; do
PGPASSWORD="$PASS" psql --dbname="$I" --host="$HOST" --port="$PORT" --username="$USER" -with --command "analyze VERBOSE" 2>> "$(pwd)"/log/analyze.log
done
date >> "$(pwd)"/log/analyze.log
echo "end analyze" >> "$(pwd)"/log/analyze.log
mail -s 'Service "ANALYZE PostgreSQL"' "$MAILTO" < "$(pwd)"/log/analyze.log
