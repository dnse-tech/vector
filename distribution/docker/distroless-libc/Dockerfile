FROM docker.io/debian:trixie-slim@sha256:b6e2a152f22a40ff69d92cb397223c906017e1391a73c952b588e51af8883bf8 AS builder

WORKDIR /vector

COPY vector_*.deb ./
RUN dpkg -i vector_*_"$(dpkg --print-architecture)".deb

RUN mkdir -p /var/lib/vector

# Stage libz at its arch-specific path so it can be copied into the distroless
# runtime. distroless/cc does not include zlib; vector (via rdkafka) links
# against it dynamically and we deliberately keep it as a runtime dependency.
RUN src=$(dpkg -L zlib1g | grep -E '/libz\.so\.1$') && \
    install -D "$(realpath "$src")" "/staging${src}"

# Use the debian13 (trixie, glibc 2.41) distroless base: the s390x vector binary
# is built natively on Ubuntu 24.04 (glibc 2.39), so the older cc-debian12 base
# (glibc 2.36) cannot run it. trixie's glibc satisfies the binary's requirement
# and matches the trixie builder stage that stages libz above.
# distroless doesn't use static tags
# hadolint ignore=DL3007
FROM gcr.io/distroless/cc-debian13:latest

# https://github.com/opencontainers/image-spec/blob/main/annotations.md
LABEL org.opencontainers.image.url="https://vector.dev"
LABEL org.opencontainers.image.source="https://github.com/vectordotdev/vector"
LABEL org.opencontainers.image.documentation="https://vector.dev/docs"

COPY --from=builder /usr/bin/vector /usr/bin/vector
COPY --from=builder /usr/share/doc/vector /usr/share/doc/vector
COPY --from=builder /usr/share/vector /usr/share/vector
COPY --from=builder /etc/vector /etc/vector
COPY --from=builder /var/lib/vector /var/lib/vector
COPY --from=builder /staging/ /

# Smoke test
RUN ["vector", "--version"]

ENTRYPOINT ["/usr/bin/vector"]
