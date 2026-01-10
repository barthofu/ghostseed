# ==================
# == dependencies ==
# ==================

FROM lukemathwalker/cargo-chef:latest AS chef

    WORKDIR /app

    # use chef to prepare the dependency tree json
    FROM chef AS planner
    COPY . .
    RUN cargo chef prepare --recipe-path recipe.json

# ==================
# ==== builder =====
# ==================

FROM chef as builder

    # first, build the dependencies in a separate layer, in order to cache 
    # them and avoid rebuilding them every time the source code changes
    COPY --from=planner /app/recipe.json .
    RUN cargo chef cook --release --recipe-path recipe.json

    # copy all the source code
    COPY . .

    # build the application
    RUN cargo build --release --bin server

# ==================
# ==== runner ======
# ==================

FROM debian:buster-slim as runner

    WORKDIR /app

    # create a user and a group to run the app more securely and properly
    RUN addgroup --system --gid 1001 server \
        && adduser --system --uid 1001 server

    # install needed libraries
    RUN apt-get update && apt-get install -y --no-install-recommends \
        libpq-dev \
        && rm -rf /var/lib/apt/lists/*

    # copy needed files for the binary from the previous stage
    COPY --from=builder /app/Rocket.toml .
    # copy the binary from the previous stage
    COPY --from=builder /app/target/release/server .

    USER server

    # start the app
    CMD ["./server"]