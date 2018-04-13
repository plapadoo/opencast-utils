#!/usr/bin/env bash

# Call from Opencast parent directory, rebuild all changed modules
# (using git status to check dirtyness) and put them to
# build/.../system

set -eu

if [ ! -f "pom.xml" ]; then
    echo "pom.xml not found in current working directory"
    echo "are you in the opencast parent directory?"
    exit 1
fi

if ! command -v mvn >/dev/null; then
    echo "command \"mvn\" not found. is maven installed?"
    exit 2
fi

echo "determining OC version..."
echo "(this might take a while on first launch)"
version="$(mvn -q -Dexec.executable="echo" -Dexec.args='${project.version}' --non-recursive org.codehaus.mojo:exec-maven-plugin:1.3.1:exec)"
echo "OC version is: $version"

relative="$1"
shift

modules=$(git diff --name-only "$relative" | sed -e '/^etc/d' -e '/^docs/d' -e 's/modules\/\([^/]*\)\/.*/modules\/\1/' | sort -u | paste -s -d, -)

echo "rebuilding $modules via maven"
mvn install -pl "$modules" "$@"

echo "installing"

git diff "$relative" --name-only | sed -e '/^etc/d' -e '/^docs/d' -e 's/modules\/\([^/]*\)\/.*/\1/' | sort -u | while read -r line; do
    echo "installing $line"
    oc_path="org/opencastproject/opencast-$line/$version/opencast-$line-$version.jar"
    from_path="$HOME/.m2/repository/$oc_path"
    to_path="build/opencast-dist-develop-$version/system/$oc_path"
    if [ ! -f "$from_path" ]; then
	echo "origin $from_path does not exist"
	exit 1
    fi
    if [ ! -f "$to_path" ]; then
	echo "destination $to_path does not exist"
	exit 1
    fi
    cp "$from_path" "$to_path"
done


