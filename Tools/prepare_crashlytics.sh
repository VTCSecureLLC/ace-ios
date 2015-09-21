#!/bin/bash

if [ -z "$FABRIC_API_KEY" ]; then
  echo "FABRIC_API_KEY is empty"
  exit 1
fi

if [ -z "$FABRIC_API_SECRET" ]; then
  echo "FABRIC_API_SECRET is empty"
  exit 1
fi

cat <<EOF > fabric.properties
apiSecret=$FABRIC_API_SECRET
apiKey=$FABRIC_API_KEY
EOF

