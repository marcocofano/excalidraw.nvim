#!/bin/sh

set -e  # Exit on any error

# Configurable variables
VERSION_FILE="VERSION"

# Function to display the current version
show_version() {
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE"
    else
        echo "No version file found. Initialize with --bump or -b (major, minor, fix)." >&2
        exit 1
    fi
}

# Function to bump the version
bump_version() {
    bump_type="$1"

    if [ -z "$bump_type" ]; then
        echo "Error: Specify the bump type (major, minor, fix) with --bump or -b." >&2
        exit 1
    fi

    # Ensure the VERSION file exists
    if [ ! -f "$VERSION_FILE" ]; then
        echo "0.0.0" > "$VERSION_FILE"
    fi

    # Read the current version
    current_version=$(cat "$VERSION_FILE")

    # Extract major, minor, and patch components
    major=$(echo "$current_version" | cut -d. -f1)
    minor=$(echo "$current_version" | cut -d. -f2)
    patch=$(echo "$current_version" | cut -d. -f3)

    # Increment the appropriate version part
    case "$bump_type" in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        fix)
            patch=$((patch + 1))
            ;;
        *)
            echo "Error: Invalid bump type '$bump_type'. Use 'major', 'minor', or 'fix'." >&2
            exit 1
            ;;
    esac

    # Create the new version
    new_version="$major.$minor.$patch"
    echo "$new_version" > "$VERSION_FILE"
    echo "Version bumped to $new_version"
}

# Main script logic
main() {
    if [ "$#" -eq 0 ]; then
        show_version
        exit 0
    fi

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --bump|-b)
                shift
                bump_version "$1"
                exit 0
                ;;
            --help|-h)
                echo "Usage: $0 [--bump|-b <major|minor|fix>] [--help|-h]"
                echo "  --bump, -b    Bump the version (major, minor, or fix)"
                echo "  --help, -h    Show this help message"
                exit 0
                ;;
            *)
                echo "Error: Unknown argument '$1'. Use --help for usage information." >&2
                exit 1
                ;;
        esac
    done
}

main "$@"
