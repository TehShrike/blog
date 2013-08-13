#!/usr/bin/env observr

watch( '(.*)\.md' )  {|md| cmd = "markdown #{md[0]} > #{md[1]}.html"; puts cmd; system(cmd) }
