#!/bin/sh

TAG=$(git describe --abbrev=0 --tags --match="v[0-9]*\.[0-9]*" 2>/dev/null)

# Is there a tag?
if [ $? != 0 ]; then
  # No tag was found, go from initial commit
  PATCH=$(git rev-list master --count 2>/dev/null)
  TAG=v0.0
else
  # Tag was found, go from there
  PATCH=$(git rev-list $TAG..master --count 2>/dev/null)
fi

# Split out tag into major, minor and patch numbers
MAJOR=$(echo $TAG | cut -c 2- | cut -d "." -f 1)
MINOR=$(echo $TAG | cut -c 2- | cut -d "." -f 2)

# Output version number in the desired format
if [ $PATCH = 0 ]; then
  printf '%d.%d' "$MAJOR" "$MINOR"
else
  printf '%d.%d.%d' "$MAJOR" "$MINOR" "$PATCH"
fi

# Get the current checked out branch
BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Add the build tag on non-master branches
if [ $BRANCH != "master" ]; then
  # Get the number of merges on the current branch since that tag
  BUILD=$(git rev-list master...$BRANCH --count)

  # Append builds since last branch, if appropriate
  if [ $BUILD != 0 ]; then
    printf -- "-$BRANCH-%04d" "$BUILD"
  else
    printf -- "-$BRANCH"
  fi
fi

