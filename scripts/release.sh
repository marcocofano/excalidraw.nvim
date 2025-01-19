#!/bin/bash

set -e  # Exit on any error

# Configurable variables
VERSION_SCRIPT="scripts/version.sh"
PREPARE_CHANGELOG_SCRIPT="scripts/update_changelog.lua"
BRANCH="main"
TAG_PREFIX="v"  # Prefix for tags, e.g., "v1.2.3"

# Flags
DRY_RUN=false

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                ;;
            *)
                echo "Unknown argument: $1"
                exit 1
                ;;
        esac
        shift
    done
}

# Check if the current branch is clean from uncommitted changes
check_git_status() {
    if ! git diff-index --quiet HEAD --; then
        echo "Error: There are uncommitted changes in the repository."
        exit 1
    fi
}

get_latest_tag() {
    git fetch --tags
    git tag --list --sort=-v:refname | head -n 1
}

get_version() {
    bash "$VERSION_SCRIPT"
}

bump_version() {
    local bump_type=$1
    bash "$VERSION_SCRIPT" --bump "$bump_type"
}

prepare_changelog() {
    local new_tag=$1
    export TAG="$new_tag"
    lua "$PREPARE_CHANGELOG_SCRIPT"
}

create_and_push_tag() {
    local new_tag=$1

    if [[ $DRY_RUN == true ]]; then
        echo "[Dry Run] Would commit changelog and create tag $new_tag"
        return
    fi

    git add CHANGELOG.md
    git add VERSION
    git commit -m "chore(release): update changelog for $new_tag"
    git tag -a "$new_tag" -m "Release $new_tag"
    git push origin "$new_tag"
    git push origin "$BRANCH"
}

main() {
    parse_arguments "$@"

    check_git_status

    echo "Fetching the latest tag..."
    latest_tag=$(get_latest_tag)
    local_version=$(get_version)
    if [ -z $latest_tag ]; then
        latest_tag=$local_version
    fi


    echo "Latest tag found: ${latest_tag}. Local version: ${TAG_PREFIX}${local_version}"
    if [ $latest_tag != ${TAG_PREFIX}${local_version} ]; then
        echo "Local version and latest tag do not coincide. You might want to check manually"
        exit 1
    fi
    echo "What type of version bump do you want? (major, minor, fix)"

    read -r bump_type

    echo "Bumping version ($bump_type)..."
    bump_version "$bump_type"

    echo "Fetching the new version tag..."
    new_tag=$(cat VERSION)
    new_tag="${TAG_PREFIX}${new_tag}"
    echo "New version tag: $new_tag"

    echo "Preparing the changelog..."
    prepare_changelog "$new_tag"

    echo "Creating and pushing new tag..."
    create_and_push_tag "$new_tag"

    echo "Release process completed successfully!"
}

main "$@"
