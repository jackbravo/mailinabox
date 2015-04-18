#!/bin/bash
# Updates an existing Mail-in-a-Box installation to a newer tag.
################################################################

# Are we running as root?
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root. Did you leave out sudo?"
	exit
fi

# Was a tag specified on the command line?
TAG=$1
if [ -z "$TAG" ]; then
	echo "Usage: setup/upgrade.sh TAGNAME"
	exit 1
fi

# Is Mail-in-a-Box already installed?
if [ ! -d $HOME/mailinabox ]; then
	echo Could not find your Mail-in-a-Box installation at $HOME/mailinabox.
	exit 1
fi

# Change directory to it.
cd $HOME/mailinabox

# Are we on that tag?
if [ "$TAG" == `git describe` ]; then
	echo "You already have Mail-in-a-Box $TAG. Run"
	echo "  sudo setup/start.sh"
	echo "if there are any problems."
	exit 1
fi

# Fetch that tag.
echo Updating Mail-in-a-Box to $TAG . . .
git fetch --depth 1 --force --prune origin tag $TAG

# Check that the tag was signed by the key that we expect, to guard against
# the remote repository being compromised after the first time Mail-in-a-Box
# was installed.
if ! git verify-tag $TAG 2>&1 | grep C10BDD81 > /dev/null; then
	echo "$TAG was not signed by the Mail-in-a-Box authors. This could"
	echo "indicate the github repository has been compromised. Check"
	echo "https://twitter.com/mailinabox and https://mailinabox.email/"
	echo "for further instructions."
	exit 1
fi

# Check that we're moving to a later version, not backwards.
CUR_VER_TIMESTAMP=$(git show -s --format="%ct") # commit time of HEAD
NEW_VER_TIMESTAMP=$(git show -s --format="%ct" $TAG^{tag}^{commit}) # commit time of the commit that the tag tags
if [ -z "$NEW_VER_TIMESTAMP" ]; then echo "$TAG is not a version of Mail-in-a-Box."; exit 1; fi
if [ $CUR_VER_TIMESTAMP -gt $NEW_VER_TIMESTAMP ]; then
	echo -n "$TAG is older than the version you currently have installed: "
	git describe
	exit 1
fi

exit 0

# Checkout the tag.
if ! git checkout -q $TAG; then
	echo "Update failed. Did you modify something in `pwd`?"
	exit
fi

# Start setup script.
setup/start.sh
