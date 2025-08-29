# Testing GitHub Actions Locally with Act

This guide explains how to test the Vector s390x build workflows locally using `act`.

## Prerequisites

1. **Install act**: 
   ```bash
   brew install act
   # or
   curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
   ```

2. **Docker must be running**:
   ```bash
   # Start Docker Desktop on macOS
   open -a Docker
   # Or use colima/podman as alternative
   ```

3. **Set up GitHub token** (optional, for GHCR access):
   ```bash
   export GITHUB_TOKEN=your_github_token
   ```

## Testing Workflows

### 1. Test Cross-Compilation (Simplest)

Test the cross-compilation for x86_64 and s390x:

```bash
# Test only s390x cross-compilation
act -W .github/workflows/cross.yml \
    --container-architecture linux/amd64 \
    -P ubuntu-24.04=catthehacker/ubuntu:act-24.04 \
    --matrix target:s390x-unknown-linux-gnu \
    -v

# Test both x86_64 and s390x
act -W .github/workflows/cross.yml \
    --container-architecture linux/amd64 \
    -P ubuntu-24.04=catthehacker/ubuntu:act-24.04 \
    -v
```

### 2. Test Simplified Publish Workflow

The simplified publish workflow builds x86_64 and s390x binaries and publishes to GHCR.

#### Test Metadata Generation (Quick test)
```bash
act workflow_call \
    -W .github/workflows/publish-simplified.yml \
    -j generate-publish-metadata \
    --container-architecture linux/amd64 \
    --input git_ref=refs/heads/main \
    --input channel=custom \
    -v
```

#### Test x86_64 Build
```bash
act workflow_call \
    -W .github/workflows/publish-simplified.yml \
    -j build-x86_64-unknown-linux-gnu-packages \
    --container-architecture linux/amd64 \
    -P release-builder-linux=catthehacker/ubuntu:act-24.04 \
    --input git_ref=refs/heads/main \
    --input channel=custom \
    -v
```

#### Test s390x Build (Cross-compilation)
```bash
act workflow_call \
    -W .github/workflows/publish-simplified.yml \
    -j build-s390x-unknown-linux-gnu-packages \
    --container-architecture linux/amd64 \
    -P release-builder-linux=catthehacker/ubuntu:act-24.04 \
    --input git_ref=refs/heads/main \
    --input channel=custom \
    -v
```

#### Test Docker Build (without push)
```bash
# This will build the Docker images but fail at push (which is expected locally)
act workflow_call \
    -W .github/workflows/publish-simplified.yml \
    -j publish-docker-ghcr \
    --container-architecture linux/amd64 \
    -P release-builder-linux=catthehacker/ubuntu:act-24.04 \
    --secret GITHUB_TOKEN=$GITHUB_TOKEN \
    --input git_ref=refs/heads/main \
    --input channel=custom \
    --env DOCKER_BUILDKIT=1 \
    -v
```

### 3. Test Full Workflow

Run the entire simplified publish workflow:

```bash
act workflow_call \
    -W .github/workflows/publish-simplified.yml \
    --container-architecture linux/amd64 \
    -P release-builder-linux=catthehacker/ubuntu:act-24.04 \
    --secret GITHUB_TOKEN=$GITHUB_TOKEN \
    --input git_ref=refs/heads/main \
    --input channel=custom \
    --env DOCKER_BUILDKIT=1 \
    -v
```

### 4. Test Release Trigger

Simulate a version tag push:

```bash
# Create event file
cat > release-event.json << 'EOF'
{
  "push": {
    "ref": "refs/tags/v0.47.0"
  },
  "ref": "refs/tags/v0.47.0"
}
EOF

# Run release workflow
act push \
    -W .github/workflows/release.yml \
    --container-architecture linux/amd64 \
    --eventpath release-event.json \
    -P release-builder-linux=catthehacker/ubuntu:act-24.04 \
    --secret GITHUB_TOKEN=$GITHUB_TOKEN \
    -v
```

## Troubleshooting

### Docker Credential Issues

If you see credential errors, try:

```bash
# Remove Docker credential helper from config
mv ~/.docker/config.json ~/.docker/config.json.bak
echo '{}' > ~/.docker/config.json
```

### Resource Limits

For s390x cross-compilation, ensure Docker has enough resources:
- Memory: At least 8GB
- Disk: At least 20GB free space

### Using Different Runners

Act uses different images than GitHub Actions. Map them appropriately:

```bash
-P ubuntu-24.04=catthehacker/ubuntu:act-24.04
-P ubuntu-latest=catthehacker/ubuntu:act-latest
-P release-builder-linux=catthehacker/ubuntu:act-24.04
```

### Debugging

Add `-v` for verbose output or `--debug` for maximum verbosity:

```bash
act ... -v        # Verbose
act ... --debug   # Very verbose
```

### Dry Run

To see what would be executed without running:

```bash
act ... --dryrun
```

## Quick Test Commands

```bash
# Fastest test - just check workflow syntax
act -W .github/workflows/publish-simplified.yml --dryrun

# Test s390x cross build only
act -W .github/workflows/cross.yml \
    --matrix target:s390x-unknown-linux-gnu \
    --container-architecture linux/amd64 \
    -P ubuntu-24.04=catthehacker/ubuntu:act-24.04

# Test metadata generation (quick)
act workflow_call -W .github/workflows/publish-simplified.yml \
    -j generate-publish-metadata \
    --container-architecture linux/amd64 \
    --input git_ref=main \
    --input channel=custom
```

## Notes

- Act runs workflows locally in Docker containers, so it's slower than CI
- Some GitHub Actions features may not work exactly the same in act
- The Docker push step will fail locally unless you have proper credentials
- For s390x, we use cross-compilation on x86_64, not native s390x runners