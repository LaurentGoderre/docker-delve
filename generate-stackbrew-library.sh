#!/usr/bin/env bash
set -eu

declare -A aliases=(
	[1.23]='1 latest'
)

self="$(basename "$BASH_SOURCE")"
cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

if [ "$#" -eq 0 ]; then
	versions="$(jq -r 'keys | map(@sh) | join(" ")' versions.json)"
	eval "set -- $versions"
fi

# sort version numbers with highest first
IFS=$'\n'; set -- $(sort -rV <<<"$*"); unset IFS

# get the most recent commit which modified any of "$@"
fileCommit() {
	git log -1 --format='format:%H' HEAD -- "$@"
}

# get the most recent commit which modified "$1/Dockerfile""
dirCommit() {
	local dir="$1"; shift
	(
		cd "$dir"
		fileCommit \
			Dockerfile
	)
}

arches="arm64v8, arm32v7, i386, amd64"

cat <<-EOH
# this file is generated via https://github.com/LaurentGoderre/docker-delve/blob/$(fileCommit "$self")/$self

Maintainers: Laurent Goderre <laurent.goderre@gmail.com> (@LaurentGoderre)
GitRepo: https://github.com/LaurentGoderre/docker-delve.git
Architectures: $arches
EOH

# prints "$2$1$3$1...$N"
join() {
	local sep="$1"; shift
	local out; printf -v out "${sep//%/%%}%s" "$@"
	echo "${out#$sep}"
}

for version; do
	export version

	variants="$(jq -r '.[env.version].variants | map(@sh) | join(" ")' versions.json)"
	eval "variants=( $variants )"

	go="$(jq -r '.[env.version].go' versions.json)"

	fullVersion="$(jq -r '.[env.version].version' versions.json)"

	versionAliases=()
	while [ "$fullVersion" != "$version" -a "${fullVersion%[.]*}" != "$fullVersion" ]; do
		versionAliases+=( $fullVersion )
		fullVersion="${fullVersion%[.]*}"
	done
	versionAliases+=(
		$version
		${aliases[$version]:-}
	)

	for variant in "${variants[@]}"; do
		dir="$version/$variant"
		commit="$(dirCommit "$dir")"

		variantAliases=( "${versionAliases[@]/%/-$variant}" )
		variantAliases=( "${variantAliases[@]//latest-/}" )

		case "$variant" in
			go"$go")
				variantAliases=(
				"${versionAliases[@]}"
				"${variantAliases[@]}"
			)
		esac

		echo
		cat <<-EOE
			Tags: $(join ', ' "${variantAliases[@]}")
			GitCommit: $commit
			Directory: $dir
		EOE
	done
done
