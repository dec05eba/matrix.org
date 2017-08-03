#!/bin/bash -eux

# update_docs.sh: regenerates the autogenerated files on the matrix.org site.
# At present this includes:
#   * the spec index, intro and appendices
#   * the guides and howtos
#   * the swagger UI for the API
#
# It does *not* include the client-server API spec and swagger json, which is
# generated by other scripts in this directory and then *committed to git*.

# Note that this file is world-readable unless someone plays some .htaccess hijinks

SELF="${BASH_SOURCE[0]}"
if [[ "${SELF}" != /* ]]; then
  SELF="$(pwd)/${SELF}"
fi
SELF="${SELF/\/.\///}"
cd "$(dirname "$(dirname "${SELF}")")"

SITE_BASE="$(pwd)"

# grab the latest matrix-docs build from jenkins
rm -f assets.tar.gz
wget https://matrix.org/jenkins/job/Docs/2099/artifact/assets.tar.gz

# unpack the assets tarball
tar -xzf assets.tar.gz

# copy the swagger UI into place
rm -fr unstyled_docs/api/client-server
mkdir -p unstyled_docs/api/client-server/json
cp -r swagger-ui/dist/* unstyled_docs/api/client-server/
(cd unstyled_docs && patch -p0) <scripts/swagger-ui.patch

# and the unstable spec docs
cp -ar assets/spec unstyled_docs
cp -r unstyled_docs/spec/client_server/latest.json unstyled_docs/api/client-server/json/api-docs.json

# copy the unstyled docs and add the jekyll styling
rm -rf content/docs
cp -r unstyled_docs content/docs
find "content/docs" -name '*.html' |
    xargs "./scripts/add-matrix-org-stylings.pl" "./jekyll/_includes"

# run jekyll to generate the rest of the site.
# This will generate stuff under ./jekyll/_site.
cp -Tr assets/jekyll-posts jekyll/_posts
./jekyll/generate.sh

# ... and copy it into place
cp -r jekyll/_site/{css,guides,howtos,projects} content/docs

