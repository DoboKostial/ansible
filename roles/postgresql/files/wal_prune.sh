#!/usr/bin/env bash
set -euo pipefail

ARCHIVE_DIR="${1:-/pgwal/main/archive}"
TARGET_PCT="${2:-60}"
MIN_KEEP_HOURS="${3:-24}"

# FS use %
FS_USE=$(df -P "${ARCHIVE_DIR}" | awk 'NR==2{print $5}' | tr -d '%')

#  being under threshold, stop
if [ "${FS_USE}" -lt "${TARGET_PCT}" ]; then
  exit 0
fi

# deleting older than MIN_KEEP_HOURS (with some PITR window)
# continuously until get under TARGET_PCT
while [ "${FS_USE}" -ge "${TARGET_PCT}" ]; do
  OLDEST=$(find "${ARCHIVE_DIR}" -type f -name '*.gz' -o -name '0*' -printf '%T@ %p\n' \
           | sort -n | awk '{print $2}' | head -n 50)
  if [ -z "${OLDEST}" ]; then
    # fallback - deleting files older than window
    find "${ARCHIVE_DIR}" -type f -mmin +$(( MIN_KEEP_HOURS * 60 )) -delete || true
  else
    echo "${OLDEST}" | xargs -r rm -f
  fi
  FS_USE=$(df -P "${ARCHIVE_DIR}" | awk 'NR==2{print $5}' | tr -d '%')
done

