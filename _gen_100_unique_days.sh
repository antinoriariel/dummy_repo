#!/bin/bash
set -e
start_ts=$(date -d "2025-07-06" +%s)
end_ts=$(date -d "2026-02-28" +%s)
range_days=$(( (end_ts - start_ts) / 86400 + 1 ))
count=100

rand_name() {
  local chars="abcdefghijklmnopqrstuvwxyz0123456789"
  local name=""
  while [ -f "${name}.md" ] || [ -z "$name" ]; do
    name=""
    for i in $(seq 1 10); do
      name="${name}${chars:RANDOM%36:1}"
    done
  done
  echo "$name"
}

offsets=$(seq 0 $((range_days-1)) | shuf -n $count | sort -n)

for offset in $offsets; do
  cur_ts=$((start_ts + offset*86400))
  day=$(date -d "@$cur_ts" +%d)
  mon=$(date -d "@$cur_ts" +%m)
  yr=$(date -d "@$cur_ts" +%Y)
  hh=$(printf "%02d" $((RANDOM % 24)))
  mm=$(printf "%02d" $((RANDOM % 60)))
  name=$(rand_name)
  printf "%s - %s/%s/%s %s:%s\r\n" "$name" "$day" "$mon" "$yr" "$hh" "$mm" > "${name}.md"
  git add "${name}.md"
  export GIT_AUTHOR_DATE="${yr}-${mon}-${day}T${hh}:${mm}:00-03:00"
  export GIT_COMMITTER_DATE="$GIT_AUTHOR_DATE"
  git commit -q -m "Add ${name}.md"
  echo "committed ${name}.md for ${yr}-${mon}-${day}"
done
echo "DONE"
