#!/bin/sh

set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)

export DOTFILES_ROOT=$ROOT

run_test() {
    name=$1
    script=$2
    printf '%s\n' "==> $name"
    "$ROOT/tests/$script"
}

run_test "rendering" unit/test-rendering.sh
run_test "package catalog" unit/test-package-catalog.sh

printf '%s\n' 'All tests passed.'
