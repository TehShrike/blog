#!/usr/bin/env observr

watch( '(.*)\.md' )  {|md| cmd = "stmd #{md[0]} > #{md[1]}.html"; puts cmd; system(cmd) }
