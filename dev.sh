
#!/usr/bin/env bash
# dev.sh — quick helpers for the Ubuntu 24.04 dev container
set -euo pipefail
 
# Auto-fill UID/GID from the current host user
export HOST_UID=$(id -u)
export HOST_GID=$(id -g)
 
CMD=${1:-shell}
 
case "$CMD" in
  build)
    echo "==> Building image..."
    docker compose build
    ;;
  shell)
    echo "==> Dropping into container shell (project mounted at /workspace)..."
    docker compose run --rm devtmp /bin/bash
    ;;
  up)
    echo "==> Starting container in background..."
    docker compose up -d
    ;;
  exec)
    echo "==> Exec into running container..."
    docker compose exec -it dev /bin/bash
    ;;
  down)
    docker compose down
    ;;
  *)
    echo "Usage: $0 {build|shell|up|exec|down}"
    exit 1
    ;;
esac

