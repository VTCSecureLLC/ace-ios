#!/bin/bash

if [ -z "$FABRIC_API_KEY" ]; then
  echo "FABRIC_API_KEY is empty"
fi

if [ -z "$FABRIC_API_SECRET" ]; then
  echo "FABRIC_API_SECRET is empty"
fi

cat <<EOF > fabric.properties
apiSecret=$FABRIC_API_SECRET
apiKey=$FABRIC_API_KEY
EOF

