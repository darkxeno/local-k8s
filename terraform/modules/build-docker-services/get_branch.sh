
# get_branch.sh
#!/bin/bash
set -euo pipefail

echo '{"branch": "'"$(git rev-parse --abbrev-ref HEAD)"'"}'