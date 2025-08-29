#!/bin/bash

# Test cross-compilation workflow locally with act

echo "Testing Vector cross-compilation for x86_64 and s390x..."

# Run the cross workflow for both architectures
act -W .github/workflows/cross.yml \
    --container-architecture linux/amd64 \
    -P ubuntu-24.04=catthehacker/ubuntu:act-24.04 \
    --matrix target:x86_64-unknown-linux-gnu \
    --matrix target:s390x-unknown-linux-gnu \
    -v

# Alternative: Test only s390x
# act -W .github/workflows/cross.yml \
#     --container-architecture linux/amd64 \
#     -P ubuntu-24.04=catthehacker/ubuntu:act-24.04 \
#     --matrix target:s390x-unknown-linux-gnu \
#     -v