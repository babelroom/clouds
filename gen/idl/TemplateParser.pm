#  Jeeves software originally copied from 
#  "Advanced Perl Programming" by Sriram Srinivasan,
#  O'Reilly & Associates 1997.
#  ISBN: 1-56592-220-4
#
# see: http://oreilly.com/pub/a/oreilly/ask_tim/2001/codepolicy.html
#  
#  Modified by John Roy
#

package TemplateParser;

#-----------------------------------------------------------------------------
# This package parses a template file in the format explained below, and
# translates it into Perl code. See jeeves for where this package fits
# into the scheme of things.
# The template file recognizes the following directives ...
#   (keywords are case insensitive)
#   @OPENFILE <filename> [options] - closes the previous output file, 
#         the new file. 
#         Options: 
#            -append - open the file in append mode
#            -no_overwrite - do not overwrite the file if it already exists. 
#                  This is useful if you want to generate the file only once.
#            -only_if_different - puts all the output into a temp file, does a 
#                  diff with the given file, and overwrites it if the two 
#                  files differ - useful in a make environment, where you
#                  don't want to unnecessarily touch the file if the contents
#                  are the same, to preserve timestamps
#
#   @PERL <perl code> - Inserts the perl code in the output file untranslated
#   @FOREACH <var> [perl condition code] - iterates thru the array @var, using 
#                  the iterator variable $var_i. The iteration works 
#                  wherever the condition is true.
#
#   @END - terminates the loop
#
#	@COND (<condition>) - output a line only if a condition is true
#	@REVERSE <var> [perl condition code] - as above - but in reverse.
#	@LENGTHOF	- probably not used
#	@IF <condition> - start a conditional block
#   @ENDIF - end a conditional block started by @IF
#	@ELSIF
#	@ELSE
#	@MUSTBETRUE
#
#   @NEXT - unconditionally breaks out of a @FOREACH loop gracefully
#   @NEXT IF (<condition>); - breaks out of a @FOREACH loop gracefully
#                             if <condition> is true
#
#   @//  - comment line, not reproduced in the intermediate perl file
#   All other lines in the template are left essentially untranslated.
#                                                               ... Sriram
#
#   @' - verbatim, enclose in single quotes, don't expand escapes, variables
#               - JR
#-----------------------------------------------------------------------------

sub parse {
    # Args : template file, intermediate perl file
	my( $pkg, $template_file, $inter_file) = @_;	
    unless (open (T, $template_file)) {
		warn "$template_file : $@";
		return 1;
    }
    open (I, "> $inter_file") || 
		die "Error opening intermediate file $inter_file : $@";
    
	emit_opening_stmts($template_file);
	my $line;
	while (defined($line = <T>)) {
        $line =~ s/\r$//;

		if ( $line !~ /^\s*\@/) { # Is it a command?
			emit_text($line);
			next;
		}
		if ( $line =~ /^\s*\@OPENFILE\s*(.*)\s*$/i) {
			emit_open_file($1);
		} elsif ($line =~ /^\s*\@FOREACH\s*(\w*)\s*(.*)\s*/i) {
			emit_loop_begin($1,$2);
		} elsif ($line =~ /^\s*\@REVERSE\s*(\w*)\s*(.*)\s*/i) {
			emit_loop_begin_rev($1,$2);
		} elsif ($line =~ /^\s*\@COND\s*(\(.*\))(.*)\s*/i) {
			emit_condition($1,$2);
		} elsif ($line =~ /^\s*\@LENGTHOF\s*(.*)\s*$/i) {
			emit_lengthof($1);
		} elsif ($line =~ /^\s*\@MUSTBETRUE\s*(.*)\s*/i) {
			emit_mustbetrue($1);
		} elsif ($line =~ /^\s*\@IF\s*(.*)\s*/i) {
			emit_if($1);
		} elsif ($line =~ /^\s*\@ELSIF\s*(.*)\s*/i) {
			emit_elsif($1);
		} elsif ($line =~ /^\s*\@ELSE/i) {
			emit_else();
		} elsif ($line =~ /^\s*\@ENDIF/i) {
			emit_endif();
		} elsif ($line =~ /^\s*\@END/i) {
			emit_loop_end();
		} elsif ($line =~ /^\s*\@NEXT IF(.*);/i) {
			#emit_perl("if ($1) { Ast->bye(); next; }\n");
			emit_perl("if ($1) { bye(); next; }\n");
		} elsif ($line =~ /^\s*\@NEXT/i) {
			#emit_perl("Ast->bye(); next; \n");
			emit_perl("bye(); next; \n");
		} elsif ($line =~ /^\s*\@PERL(.*)/i) {
			emit_perl("$1\n");
		} elsif ($line =~ /^\s*\@'(.*)/i) {
			emit_verbatim_text($1);
		} elsif ($line =~ /^\s*\@\/\//i) {
			;
		} else {
			die "Unknown command '$line' at line $.\n"; 
		};
    }
	emit_closing_stmts();
    
    close(I);
    return 0;
}

# All pieces of output code are within a "here" document terminated 
# by _EOC_
#

#----------------------------------------------------------------------
# emit_opening_stmts
# ==> emit ("Convert ROOT's properties to global variable names")
#
sub emit_opening_stmts {
	my $template_file = shift;
    emit("# Created automatically from $template_file");
    emit(<<'_EOC_');

{
no warnings qw(redefine);

#-------------------------------------------------------------------------
sub run_generator
{
    no warnings qw(uninitialized);
    my @saved_values_stack;
    my @current_values_stack;
    $tmp_file = "jeeves.tmp";
    if (! (defined ($ROOT) && $ROOT)) {
        die "ROOT not defined \n";
        }

    $file = "> -";		# Assumes STDOUT, unless @OPENFILE changes it.
    open (F, $file) || die $@;
    visit($ROOT);

##print "[$ROOT->{_}]\n";
##print "[$_]\n";

_EOC_
}

#------------------------------------------------------------------------
# emit_open_file
# ==> emit ("Close the previous file, and open the new filename for output
#

sub emit_open_file {
    my $file = shift;
    my $no_overwrite		= ($file =~ s/-no_overwrite//gi) ? 1 : 0;
    my $append				= ($file =~ s/-append//gi) ? 1 : 0;
    my $only_if_different	= ($file =~ s/-only_if_different//gi) ? 1 : 0;
    $file =~ s/\s*//g;  # this is propably a hangover from the windows days ...

    emit (<<"_EOC_");
# Line $.
##print "[\$_]\\n";
##print "[$file]\\n";
open_file(\"$file\", $no_overwrite, $only_if_different, $append);
_EOC_
}

#----------------------------------------------------------------------
# emit_loop_begin
# ==> emit ("manufacture an iterator name, and visit each element in 
#            that array")
# The best way to understand this code is to execute the schema compiler
# and look at the intermediate perl code.
#
sub emit_loop_begin {
    my $l_name = shift; # Name of the list variable
	my $condition = process_condition( shift );
    $l_name_i = $l_name . "_i";
emit (<<"_EOC_");
# Line $.
\$_index = -1;
foreach \$$l_name_i (\@\${$l_name}) {
	#\$$l_name_i->visit ();
	visit(\$$l_name_i);
	\$_index++;
_EOC_
    if ($condition) {
		emit ("if ($condition) {\n");
    } else {
		emit ("if (1) {\n");
		};
}
#----------------------------------------------------------------------
# emit_loop_begin_rev
sub emit_loop_begin_rev {
    my $l_name = shift; # Name of the list variable
    my $condition = shift;
    $l_name_i = $l_name . "_i";
emit (<<"_EOC_");
# Line $.
my \@tmp = \@\${$l_name};
\$_index = \$\#tmp+1;
foreach \$$l_name_i (reverse \@\${$l_name}) {
	#\$$l_name_i->visit ();
	visit(\$$l_name_i);
	\$_index--;
_EOC_
    if ($condition) {
		emit ("if ($condition) {\n");
    } else {
		emit ("if (1) {\n");
		};
}
sub emit_loop_end {
    emit(<<"_EOC_");
#Line $.
		};	# condition
	#Ast->bye();
	bye();
}
_EOC_
}

# --- JR 8/2001
sub process_condition {
	my $condition = shift;
	$condition =~ s/([\w][\w|_]*)\s*\.\s*length/(\$\#{\@\${$1}}\+1)/gi;
# JR 8-15-2001
#	$condition =~ s/([\w][\w|_]*)\s*\.\s*defined/defined(\${$1})/gi;
	return $condition;
}

#----------------------------------------------------------------------
sub emit {
	print I $_[0];
}

#----------------------------------------------------------------------
sub emit_perl {
#    emit($_[0].";"); -- the semicolon breaks multiline statements such as if .. elsif else etc.
    emit($_[0]);
}

#----------------------------------------------------------------------
sub emit_condition {
	my $condition = process_condition( shift );
	my $text = shift;
    chomp $text;
    # Escape quotes in the text
    $text =~ s/"/\\"/g;
    $text =~ s/'/\\'/g;
    emit(<<"_EOC_");
output("$text\\n") if $condition;
_EOC_
}

#----------------------------------------------------------------------
sub emit_lengthof {
    my $l_name = shift; # Name of the list variable
emit (<<"_EOC_");
# Line $.
	print (\$\#{\@\${$l_name}} + 1);
_EOC_
}

#----------------------------------------------------------------------
sub emit_if {
	my $condition = process_condition( shift );
emit (<<"_EOC_");
	if ( $condition ) {
# Line $.
_EOC_
}

#----------------------------------------------------------------------
sub emit_elsif {
	my $condition = process_condition( shift );
emit (<<"_EOC_");
		}
	elsif ( $condition ) {
# Line $.
_EOC_
}

#----------------------------------------------------------------------
sub emit_else {
    emit(<<"_EOC_");
#Line $.
		}
	else {
_EOC_
}

#----------------------------------------------------------------------
sub emit_mustbetrue {
	my $condition = process_condition( shift );
    emit(<<"_EOC_");
	die "Condition failed [$condition] at line $.\n" if not $condition;
#Line $.
_EOC_
}

#----------------------------------------------------------------------
sub emit_endif {
    emit(<<"_EOC_");
#Line $.
		};	# condition
_EOC_
}

#----------------------------------------------------------------------
sub emit_text {
	my $text = $_[0];
    chomp $text;
    # Escape quotes in the text
    $text =~ s/"/\\"/g;
#    $text =~ s/'/\\'/g; -- not needed
    emit(<<"_EOC_");
output("$text\\n");
_EOC_
}

#----------------------------------------------------------------------
sub emit_verbatim_text {
	my $text = $_[0];
    chomp $text;
    # Escape quotes in the text
    $text =~ s/'/\\'/g;
    emit(<<"_EOC_");
output('$text'."\\n");
_EOC_
}

#----------------------------------------------------------------------
sub emit_closing_stmts {
	emit(<<'_EOC_');
#Ast::bye();
bye();
close(F);
unlink ($tmp_file);
}

#-------------------------------------------------------------------------
sub Ruby::as_camel{ my $s = shift; $s=~s/(?<!['])(\w+)/\u$1/g; $s=~s/_([a-z])/\u$1/g; $s; }
sub Ruby::as_literal
{
    my $v = shift;
    # TODO: various forms of floating point
    return "null" if not defined $v;
    return ($v?"true":"false") if JSON::is_bool($v);
    return $v if $v=~/^(?:0|-?[1-9]\d{0,10})\z/;      # safe decimal number (as per Data::Dumper)
    return "\"$v\"";                                # string
}
#-------------------------------------------------------------------------
sub save_and_set_var
{
    my ($var, $val, $saved_values, $current_values) = @_;
    my $old_val;
    if (defined($old_val = $$var)) {
        $$saved_values{$var} = $old_val;
    }
    $$var = $val;
    $$current_values{$var} = $val;
}
sub visit {
    no strict 'refs';
    my $node = shift;
    package main;
    my ($var, $val, $old_val, %saved_values, %current_values, $ref_type);
    $ref_type = ref($node);
    if ($ref_type eq 'HASH') {
        while (($var, $val) = each %{$node}) {
            save_and_set_var($var, $val, \%saved_values, \%current_values);
# for ref.
#            if (defined($old_val = $$var)) {
#                $saved_values{$var} = $old_val;
#            }
#            $$var = $val;
#            $current_values{$var} = $val;
            }
        }
    elsif ($ref_type eq 'ARRAY') {
        my $i = 0;
        foreach $val (@{$node}) {
            $var = "_$i";
            save_and_set_var($var, $val, \%saved_values, \%current_values);
            $i++;
            }
        }
    elsif ($ref_type eq '') {
        ($var,$val) = ('_',$node);
        save_and_set_var($var, $val, \%saved_values, \%current_values);
        }
    push (@saved_values_stack, \%saved_values);
    push (@current_values_stack, \%current_values);
}

#-------------------------------------------------------------------------
sub bye {
    my $rh_saved_values = pop(@saved_values_stack);
    my $rh_current_values = pop(@current_values_stack);
    no strict 'refs';
    package main;
    my ($var,$val);
    while (($var,$val) = each %$rh_current_values) {
        $$var = undef;
    }
    while (($var,$val) = each %$rh_saved_values) {
        $$var = $val;
    }
}

sub mkdir_p {
    my $path = shift;
    my $perms = shift;
    my @parts = split /\//, $path;
    for my $num (0..($#parts-1)) {
        my $check = join('/', @parts[0..$num]);
        next if not length($check);
        mkdir( $check, $perms ) or die "$check, $perms: $@" unless -d $check;
    }
}

sub open_file {
    my ($a_file, $a_nooverwrite, $a_only_if_different, $a_append) = @_;

    #First deal with the file previously opened
    close (F);
    if ($only_if_different) {
#		if (JeevesUtil::Compare ($orig_file, $curr_file) != 0) {
	    	rename ($curr_file, $orig_file) || 
			die "Error renaming $curr_file  to $orig_file";
#		}
    }
    #Now for the new file ...
    $curr_file = $orig_file = $a_file;
    $only_if_different = ($a_only_if_different && (-f $curr_file)) ? 1 : 0;
    $no_overwrite = ($a_nooverwrite && (-f $curr_file))  ? 1 : 0;
    $mode =  ($a_append) ? ">>" : ">";
    if ($only_if_different) {
		unlink ($tmp_file);
		$curr_file = $tmp_file;
    }
    if (! $no_overwrite) {
        mkdir_p($curr_file, 0755);
		open (F, "$mode $curr_file") || die "could not open $curr_file: $!";
#print "opening [$mode $curr_file][$a_file]\n";
    }
}

sub output {
	print F @_ if (! $no_overwrite);
}
#-------------------------------------------------------------------------
}

1;
_EOC_
}
1;
