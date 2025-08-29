#!/bin/bash

# Script to test the publish workflow locally with act

echo "Testing Vector publish workflow locally with act..."

# Create a local event file for testing
cat > .github/workflows/local-event.json << 'EOF'
{
  "workflow_call": {
    "inputs": {
      "git_ref": "refs/heads/s390x/v0.47.0",
      "channel": "custom"
    }
  }
}
EOF

# Test options
echo "Available test options:"
echo "1. Test metadata generation only"
echo "2. Test x86_64 build"
echo "3. Test s390x build"
echo "4. Test Docker publish (dry-run)"
echo "5. Run full workflow"

read -p "Select option (1-5): " option

case $option in
  1)
    echo "Testing metadata generation..."
    act -W .github/workflows/publish-simplified.yml \
        -j generate-publish-metadata \
        --container-architecture linux/amd64 \
        -e .github/workflows/local-event.json \
        --secret GITHUB_TOKEN=$GITHUB_TOKEN \
        -v
    ;;
  2)
    echo "Testing x86_64 build..."
    act -W .github/workflows/publish-simplified.yml \
        -j build-x86_64-unknown-linux-gnu-packages \
        --container-architecture linux/amd64 \
        -e .github/workflows/local-event.json \
        -P release-builder-linux=catthehacker/ubuntu:act-24.04 \
        --secret GITHUB_TOKEN=$GITHUB_TOKEN \
        -v
    ;;
  3)
    echo "Testing s390x build (will use cross-compilation)..."
    act -W .github/workflows/publish-simplified.yml \
        -j build-s390x-unknown-linux-gnu-packages \
        --container-architecture linux/amd64 \
        -e .github/workflows/local-event.json \
        -P release-builder-linux=catthehacker/ubuntu:act-24.04 \
        --secret GITHUB_TOKEN=$GITHUB_TOKEN \
        -v
    ;;
  4)
    echo "Testing Docker publish (dry-run)..."
    # This will fail at the actual push step but will test the build process
    act -W .github/workflows/publish-simplified.yml \
        -j publish-docker-ghcr \
        --container-architecture linux/amd64 \
        -e .github/workflows/local-event.json \
        -P release-builder-linux=catthehacker/ubuntu:act-24.04 \
        --secret GITHUB_TOKEN=${GITHUB_TOKEN:-dummy-token} \
        --env DOCKER_BUILDKIT=1 \
        -v
    ;;
  5)
    echo "Running full workflow..."
    act -W .github/workflows/publish-simplified.yml \
        --container-architecture linux/amd64 \
        -e .github/workflows/local-event.json \
        -P release-builder-linux=catthehacker/ubuntu:act-24.04 \
        --secret GITHUB_TOKEN=${GITHUB_TOKEN:-dummy-token} \
        --env DOCKER_BUILDKIT=1 \
        -v
    ;;
  *)
    echo "Invalid option"
    exit 1
    ;;
esac