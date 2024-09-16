#!/usr/bin/env -S dumb-init bash

function fatal() { error "$*"; exit $E_ERROR; }

function run() {
  xcodebuild test -scheme Cheq -destination 'platform=iOS Simulator,name=iPhone 15' || fatal "failed to run tests"
  rm -rf docs-build
  xcodebuild docbuild -scheme Cheq -destination 'platform=iOS Simulator,name=iPhone 15' -derivedDataPath docs-build || fatal "failed to build docs"
}

run "$@"
