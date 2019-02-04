#!/usr/bin/env sh

set -o errexit
set -o pipefail
set -o nounset

TODAY=$(date +'%s')
TODAY_KEY=$TODAY.key
ARCHIVE_DIR=/mnt/pg_archive/basebackup-$TODAY
PUBLIC_KEY=/opt/scripts/key.pub
OUT_KEY=basebackup-key.enc
IN_FILES="base.tar.gz pg_wal.tar.gz"

pg_basebackup -U postgres -h 127.0.0.1 -D "$ARCHIVE_DIR" -Ft -z

cd "$ARCHIVE_DIR"

test ! -f "$PUBLIC_KEY" && exit 1

openssl rand -base64 32 > "$TODAY_KEY"
openssl rsautl -encrypt -inkey "$PUBLIC_KEY" -pubin -in "$TODAY_KEY" -out "$OUT_KEY"

for i in $IN_FILES; do
    openssl enc -aes-256-cbc -salt -in "$i" -out "$i.enc" -pass file:"$TODAY_KEY"
    rm "$i"
done

rm "$TODAY_KEY"