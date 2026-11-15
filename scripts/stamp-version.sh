#!/bin/sh
# Writes version.json for the commit being deployed. Spec: APP-PRINCIPLES.md §1.
# Usage: stamp-version.sh [output-path]      (default ./version.json)
# Version comes from $APP_VERSION, else package.json, else a VERSION file, else the commit date (2026.11.15).
set -eu
out="${1:-version.json}"
build_time="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
commit=""; commit_time=""; event="build"
if git rev-parse --git-dir >/dev/null 2>&1; then
  commit="$(git rev-parse --short=7 HEAD)"
  commit_time="$(git log -1 --format=%cI HEAD)"
  event="commit"
  # Uncommitted changes: the commit no longer describes what ships, so fall back to the build time.
  if [ -n "$(git status --porcelain --untracked-files=no)" ]; then commit="${commit}-dirty"; event="build"; fi
fi
version="${APP_VERSION:-}"
if [ -z "$version" ] && [ -f package.json ]; then
  version="$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' package.json | head -n 1 | sed 's/.*"\([^"]*\)"$/\1/')"
fi
if [ -z "$version" ] && [ -f VERSION ]; then version="$(head -n 1 VERSION | tr -d '[:space:]')"; fi
if [ -z "$version" ] && [ -n "$commit_time" ]; then version="$(printf %s "$commit_time" | cut -c1-10 | tr - .)"; fi
printf '{"version":"%s","commit":"%s","commitTime":"%s","buildTime":"%s","event":"%s"}\n' \
  "$version" "$commit" "$commit_time" "$build_time" "$event" > "$out"
cat "$out"
