#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
while IFS= read -r -d '' file; do
 if [[ $(head -n 1 "$file") == '#!/usr/bin/env bash' ]]; then
  bash -n "$file"
  if command -v shellcheck >/dev/null; then shellcheck -e SC1091 "$file"; fi
 fi
done < <(find "$root" -path "$root/.git" -prune -o -type f -print0)
python3 "$root/scripts/check.py"
echo 'All checks passed.'
