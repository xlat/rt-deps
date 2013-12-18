rt-deps version 0.01
====================

This module will install a hook sub in @INC and look for each file 
required and keep track of it's caller. So you could rebuild
runtime dependencies tree.

INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

DEPENDENCIES

This module requires these other modules and libraries:

  Data::Dumper
  
  and possibly others.

COPYRIGHT AND LICENCE

Copyright (C) 2013 by Nicolas Georges.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.
