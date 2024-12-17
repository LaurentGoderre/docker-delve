#!/bin/bash
set -e

globalExcludeTests+=(
	# single-binary image
	[docker-delve_no-hard-coded-passwords]=1
	[docker-delve_utc]=1
)