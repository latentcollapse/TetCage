#!/bin/sh
# Fetch the pinned primary source (Gruen et al., HPG 2026) into references/,
# verify it against references/paper.sha256, and extract references/paper.txt
# (the docs cite paper.txt line ranges). The paper is AMD's; it is fetched
# from the authors' page, never committed.
set -eu
cd "$(dirname "$0")/.."
pdf=references/TetrahedralMeshes_AuthorsVersion.pdf
url=https://gpuopen.com/download/TetrahedralMeshes_AuthorsVersion.pdf
[ -f "$pdf" ] || curl -fL --retry 3 -o "$pdf" "$url"
sha256sum -c references/paper.sha256
pdftotext -layout "$pdf" references/paper.txt
echo "references/paper.txt: $(wc -l < references/paper.txt) lines"
