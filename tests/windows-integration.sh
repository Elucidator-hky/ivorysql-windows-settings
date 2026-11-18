#!/usr/bin/env bash
set -eu -o pipefail

work=$(pwd -P)
export PATH="$work/install/bin:$PATH"
export PGHOST=127.0.0.1 PGPORT=55433 PGUSER=ivorycheck PGDATABASE=postgres
export PGCONNECT_TIMEOUT=8

pg_config --version
psql --version
sharedir=$(cygpath -u "$(pg_config --sharedir)")
test -f "$sharedir/extension/ivorysql_ora.control"
install -m 0644 pg-track-settings/pg_track_settings.control pg-track-settings/*.sql "$sharedir/extension/"

for mode in pg oracle; do
  cluster="$work/db-$mode"
  native_cluster=$(cygpath -am "$cluster")
  native_log=$(cygpath -am "$work/db-$mode-server.log")
  initdb -D "$native_cluster" -m "$mode" -U "$PGUSER" -A trust --no-locale
  pg_ctl -D "$native_cluster" -l "$native_log" -w -o "-p $PGPORT -c listen_addresses=127.0.0.1" start
  trap 'pg_ctl -D "$native_cluster" -m fast -w stop || true' EXIT
  psql -X -v ON_ERROR_STOP=1 -v expected_mode="$mode" -f "$(cygpath -am tests/verify.sql)"
  pg_ctl -D "$native_cluster" -m fast -w stop
  trap - EXIT
done
