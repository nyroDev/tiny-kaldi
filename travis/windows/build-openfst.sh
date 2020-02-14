#!/usr/bin/env bash

set -euo pipefail

# Build OpenFST in travis/openfst
OPENFST_DIR="${TRAVIS_BUILD_DIR}/travis/openfst"
(
	echo "Starting OpenFST build at $(date)"
	source "$(dirname "$0")/util.sh"

	check_travis_remaining_time_budget_s 2400
	mkdir -p "$OPENFST_DIR"
	cd "$OPENFST_DIR"
	if [ -f .valid-cache ]; then
		echo "Reusing cached OpenFST build artifacts: $(cat .valid-cache)"
	else
		if [ -d .git ]; then
			echo "Found cached OpenFST repo. Doing git pull..."
			git pull
		else
			echo "Cloning OpenFST git repo..."
			git clone -b winport --single-branch https://github.com/kkm000/openfst .
			echo "Applying patches..."
			curl https://patch-diff.githubusercontent.com/raw/kkm000/openfst/pull/22.patch | git apply -v
		fi
		if [ ! -d build64 ]; then
			echo "Generating native Makefiles..."
			cmake -S . -B build64 -G "Visual Studio 15 2017 Win64" -DCMAKE_CONFIGURATION_TYPES=Release "-DCMAKE_TOOLCHAIN_FILE=${TRAVIS_BUILD_DIR}/conan_paths.cmake" -DHAVE_FAR=ON -DHAVE_NGRAM=ON -DHAVE_LOOKAHEAD=ON
		fi
		if travis_wait 5 sh -c "set -eo pipefail; cmake --build build64 2>&1 | tail -n100"; then
			git describe --always > .valid-cache
			echo "OpenFST build successful: " $(cat .valid-cache)
			echo "Removing intermediate files:"
			find . -type f -name '*.ilk' -or -name '*.obj' -or -name '*.pdb' -ls -delete
		else
			echo "OpenFST build unsuccessful. Keeping intermediate files. Retry the build if it timed out."
		fi
	fi
	find_files_with_ext .lib "$OPENFST_DIR"
) >&2

echo $OPENFST_DIR
