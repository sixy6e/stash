#!/usr/bin/env python

import textwrap

f = 'multiline_string.csv'

outf = open(f, 'w')

s = """One, 
       Two, 
       Three,
       last\n
    """

s2 = ("One, "
      "Two, "
      "Three, "
      "last\n"
     )

outf.write(s)
outf.write(s2)
outf.write(textwrap.dedent(s))
outf.write(textwrap.dedent(s2))

outf.close()

