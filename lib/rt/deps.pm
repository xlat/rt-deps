package rt::deps;
our $VERSION = '0.02';
my $END = *STDERR;  #defaulted to STDERR
my $CLOSE_END;
my $FORMAT = "";
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
    elsif(/^[hv]?tree$/i){
      $FORMAT = lc $_;
    }
    else{
      open $END, '>', $_ or die "could not open '$_' for writting!";
      $CLOSE_END++;
    }
  }
}

sub get_tree_hash{
  my $nodes = { };
  my $seen = { };
  foreach my $mod (keys %deps ){        
    next if exists $seen->{$mod};
    addnode($nodes, $seen, $mod, $deps{$mod});
  }
  return $nodes;
}

sub get_tree{
  my $layout = shift // 'centered in boxes';
  my @ary;
  @ary = ary_tree( get_tree_hash() );
  require Text::Tree;
  my $tree = Text::Tree->new( @{$ary[0]} );
  return $tree->layout( $layout );
}

sub ary_tree{
    my ($htree) = @_;
    my @ary;
    foreach(keys %$htree){        
        my @children = ary_tree($htree->{$_});
        if(@children){
            push @ary, [ $_, @children ];
        }
        else{
            push @ary, [ $_ ];
        }
    }
    @ary;
}
sub findnode{
    my $mod = shift;
    if($deps{$mod}){
    }
}

sub addnode{
    my ($nodes, $seen, $mod, $children) = @_;
    my $node = $nodes->{$mod} = { };
    foreach my $child (@$children){
        unless(exists $nodes->{$child}){
            addnode($nodes, $seen, $child, $deps{$child});
        }
        if(my $cnode = delete $nodes->{$child}){
            #findnode and detach from %nodes if it exists
            #attach $cnode to parent $node
            $node->{$child} = $cnode;
        }
    }
    $seen->{$mod} = $node;
}

sub vtree_dump{
    my ($nodes, $printer, $indent) = @_;
    my $count = keys %$nodes;
    while(my ($mod, $children)=each %$nodes){
        $printer->( $indent, $mod);
        my $subindent;
        $subindent = $indent;
        $subindent =~ tr/+-/| /;
        $subindent =~ s/\|(\s*)$/ $1/ unless --$count;
        $subindent .= "+---";
        vtree_dump( $children, $printer, $subindent);
    }
}

sub get_vtree{
    my $printer = shift || sub{ print STDERR @_, "\n" };
    vtree_dump( get_tree_hash(), $printer, "" );
}

#at end of script dump deps, 
END{
  #remove hook
  @INC = grep{ "$_" ne "$hook" } @INC;
  if($END){
    if($FORMAT){
      if($FORMAT =~ /^h?tree$/){
        print $END get_tree();
      }
      elsif($FORMAT =~ /^vtree$/){
        get_vtree(sub{print $END @_, "\n"});
      }
      else{
        die "unknow output format '$FORMAT'";
      }
    }
    else{
      require Data::Dumper;
      print $END Data::Dumper->Dump( [ get_deps() ], [qw( deps )] ), "\n";
    }
    close $END if $CLOSE_END;
  }
}

1;
__END__
=head1 NAME

rt::deps - a module that keep track of first module caller at runtime.

=head1 SYNOPSIS

  perl -Mrt::deps=vtree -e"use Test::More; use Carp::Always; use strict; use warnings"
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

Accepted option are 'ignore', 'tree' and 'vtree'.

Option 'ignore' take an array ref of module to ignore or a signle string. 
It recurses, meaning that if you do:

  use rt::deps ignore => [ 'test::A' ];
  use test::A;

If test::A use test::B and test::B use test::C, you will get 

  my $deps = { };

and not:

  my $deps = { test::B => [ 'test::C' ] };

Options 'tree', 'vtree', 'htree' will change dumped output format.

=head1 LIMITATIONS

This module will think a module required but not present as a dependency, this
is because it doesn't look at %INC to assert module is realy loaded.

If something will unshift something in @INC, this module will never see it!

=head1 TODO

It would be possible to insert a final hook (push @INC, \&hookfinal) to
check for realy loaded modules, so it could be noticed as optional dependency.


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
