#!/bin/bash
foo=bar
echo $foo
if [ $foo = bar ]; then echo ok; fi

# shellcheck disable=SC2034
VERSION="1.1.2"
