#!/usr/bin/env sh

set -o errexit
set -o pipefail
set -o nounset

ARG_IN_FILE=$1
ARG_FULL_PATH=/var/lib/pgsql/10/data/$2
ARCHIVE_DIR=/mnt/pg_archive
TODAY=$(date +'%s')
TODAY_KEY=$TODAY.key
PUBLIC_KEY=/opt/scripts/key.pub
OUT_FILE=$ARG_IN_FILE-data.gz.enc
OUT_KEY=$ARG_IN_FILE-key.enc

if [ ! -f "$ARCHIVE_DIR/$ARG_IN_FILE.tar" ]; then
    cp "$ARG_FULL_PATH" "$ARCHIVE_DIR/$ARG_IN_FILE"
else
    exit 0
fi

cd $ARCHIVE_DIR

test ! -f $PUBLIC_KEY && exit 1

gzip "$ARG_IN_FILE"

openssl rand -base64 32 > "$TODAY_KEY"
openssl rsautl -encrypt -inkey "$PUBLIC_KEY" -pubin -in "$TODAY_KEY" -out "$OUT_KEY"
openssl enc -aes-256-cbc -salt -in "$ARG_IN_FILE.gz" -out "$OUT_FILE" -pass file:"$TODAY_KEY"

tar -cf "$ARG_IN_FILE.tar" "$OUT_FILE" "$OUT_KEY"

rm "$TODAY_KEY" "$OUT_KEY" "$ARG_IN_FILE.gz" "$OUT_FILE"