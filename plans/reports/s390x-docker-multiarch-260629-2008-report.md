# s390x Docker Multiarch — DONE ✅

## Goal
Build native s390x docker image, combine with upstream's other arches into a
multiarch manifest tagged plain `v0.56.0`.

## Result
Published: **`ghcr.io/dnse-tech/vector:v0.56.0`** (multiarch manifest)
- linux/amd64, linux/arm64, linux/arm/v7 — from upstream `timberio/vector:0.56.0-distroless-libc`
- linux/s390x — native build on LinuxONE runner
Intermediate arch image also pushed: `ghcr.io/dnse-tech/vector:0.56.0-s390x-distroless-libc`.

## How
Workflow `.github/workflows/s390x-docker-publish.yml` (on master, dispatchable):
1. Download released s390x `.deb` (run via curl + releases API; gh CLI absent on runner).
2. `docker build` distroless-libc image natively from the .deb; smoke-test `vector --version`.
3. Push to GHCR (auth via workflow GITHUB_TOKEN, packages:write — no secrets).
4. `docker buildx imagetools create -t v0.56.0` combining upstream multiarch image + our s390x image.

## Fixes during this task
- gh CLI not on runner → download .deb via curl + GitHub releases API.
- glibc mismatch: native binary needs GLIBC_2.39 (Ubuntu 24.04 runner); distroless
  cc-debian12 base = glibc 2.36 → `vector --version` failed. Bumped distroless-libc
  runtime base to `gcr.io/distroless/cc-debian13` (trixie, glibc 2.41). Commit on branch s390x/v0.56.0.

## Open / follow-ups
- GHCR package visibility is **internal** (org-only pull). If anonymous public pull is
  needed (e.g. external k8s), set package visibility to Public in GHCR settings. (User decision — not flipped.)
- The shipped Linux artifacts (.deb/.rpm/.tar.gz) and s390x image require glibc >= 2.39
  (built natively on Ubuntu 24.04). Fine on modern distros; not portable to old glibc.
  Upstream avoids this by building in almalinux:8 (glibc 2.28) — not replicated for the native s390x path.

## Unresolved questions
- Make `ghcr.io/dnse-tech/vector` public? Currently internal.
