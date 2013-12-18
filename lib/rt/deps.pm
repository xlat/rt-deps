package rt::deps;
our $VERSION = '0.01';
my $END = *STDERR;  #defaulted to STDERR
my $CLOSE_END;
my %deps;
my %IGNORE;
sub get_deps{ return \%deps }

sub hook{
  my ($cv, $file) = @_;
  my ($package, $filename, $line) = caller();
  $file =~ s{\.pm}{};
  $file =~ s{[\\\/]}{::}g;
  if(exists $IGNORE{$package}){
    $IGNORE{$file}++;
    #~ print STDERR "IGNORING: $file (loaded from $package)\n";
  }
  else{
    push @{$deps{$package}}, $file;
    #~ print STDERR "TRACING:  $package => $file\n";
  }
  return undef;
}

my $hook = \&hook;
unshift @INC, $hook;

sub import{
  my ($package) = shift;
  $DB::single = 1;
  while(defined($_ = shift)){
    if(/^(?:\s*|silent|off|quiet)$/i){
      $END = undef;
    }
    elsif(/^(?:1|stdout)$/i){
      $END = *STDOUT;
    }elsif(/^(?:2|stderr)$/i){
      $END = *STDERR;
    }
    elsif($_ eq 'ignore'){
      my $ignores = shift;
      $ignores = [ $ignores ] unless ref $ignores;
      die "ignore value must be an array ref!" 
        unless ref $ignores eq 'ARRAY';
      foreach my $p(@$ignores){
        $IGNORE{$p}++;
      }
      #~ print "ignoring modules: ", join(', ', keys %IGNORE), "\n";
    }
    else{
      open $END, '>', $_ or die "could not open '$_' for writting!";
      $CLOSE_END++;
    }
  }
}

#at end of script dump deps, 
END{
  #remove hook
  @INC = grep{ "$_" ne "$hook" } @INC;
  if($END){
    require Data::Dumper;
    print $END Data::Dumper->Dump( [ get_deps() ], [qw( deps )] ), "\n";
    close $END if $CLOSE_END;
  }
}

1;
__END__
=head1 NAME

rt::deps - a module that keep track of first module caller at runtime.

=head1 SYNOPSIS

  perl -Mrt::deps=stdout ourscript.pl

or

  BEGIN{ use rt::deps }
  
  ... load some modules
  
  END{ print Dumper( rt::deps::get_deps() ) }

=head1 DESCRIPTION

This module will install a hook sub in @INC and look for each file 
required and keep track of it's caller. So you could rebuild
runtime dependencies tree.

=head1 USE

The only accepted option is 'ignore' which take an array ref of module 
to ignore. It (acutaly) does not recurse, meaning that if you do:

  use rt::deps ignore => [ 'test::A' ];
  use test::A;

If test::A use test::B and test::B use test::C, you will get 

  my $deps = { test::B => [ 'test::C' ] };

=head1 SEE ALSO

http://github/xlat/rt-deps

=head1 AUTHOR

Nicolas Georges, E<lt>xlat HAT cpan DOTTE orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Nicolas Georges.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
