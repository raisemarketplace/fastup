#! /usr/bin/env bash

set -euo pipefail

fetchTopGems() {
  for page in {1..50}; do curl -sf "https://rubygems.org/stats?page=$page" |  grep -E '\s+<h3.*/gems/' | sed -r 's,.*>([^><]+)</a></h3>,\1,'; done
}

benchmark() {
  PRINT_HEADER=1 GEMS_COUNT=400 bundle exec ruby counts.rb
  # go big to small to warm up any filesystem cache
  for i in $(seq 400 -20 1); do
    GEMS_COUNT=$i bundle exec ruby counts.rb
  done
}

USE_FASTUP=1 benchmark | tee fastup.tsv
benchmark | tee nofastup.tsv
