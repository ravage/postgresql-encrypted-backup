#!/usr/bin/env sh

set -o errexit
set -o pipefail
set -o nounset

PRIVATE_KEY=$1
BASEBACKUP=$2
WALS=$3
READLINK=greadlink

decode_key()
{
    # pk, coded key
    pk=$1
    key=$2
    openssl rsautl -decrypt -inkey "$pk" -in "$key" -out "${key%.*}"
}

decode_data()
{
    # key, data
    key=$1
    data=$2
    openssl enc -d -aes-256-cbc -in "$data" -out "${data%.*}" -pass file:"$key"
}

BASEBACKUP=$($READLINK -f "$BASEBACKUP")
WALS=$($READLINK -f "$WALS")

cd "$BASEBACKUP"
test ! -d "done" && mkdir "done"

decode_key "$PRIVATE_KEY" basebackup-key.enc
mv basebackup-key.enc "done"

for i in base.tar.gz.enc pg_wal.tar.gz.enc; do
    decode_data basebackup-key $i
    mv $i "done"
done
mv basebackup-key "done"

cd "$WALS"
test ! -d "done" && mkdir "done"
test ! -d wal && mkdir wal

for i in *.tar; do
    basename=${i%.tar}
    tar -xvf "$i"
    mv "$i" "done"
    decode_key "$PRIVATE_KEY" "$basename"-key.enc
    decode_data "$basename-key" "$basename"-data.gz.enc
    gunzip "$basename-data.gz"
    rm "$basename"-key "$basename"-key.enc "$basename"-data.gz.enc
    mv "$basename"-data "$basename"
    mv "$basename" wal
done