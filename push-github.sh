#!/usr/bin/env -S dumb-init bash

if ! git remote | grep -q 'github'; then
  git remote add github git@github.com:cheq-ai/cheq-sst-swift.git
fi

git push github master --tags
