@openfile rails/$system/app/models/$_.rb
@perl $Camel__ = Ruby::as_camel($_);
@perl %tm = ('' => ':string', 'boolean' => ':boolean', 'datetime' => ':datetime', 'decimal' => ':decimal', 'email_address' => ':email_address', 'integer' => ':integer', 'string' => ':string', 'text' => ':text');
@perl $hobo_model_name = 'hobo_model' if not defined $hobo_model_name;
class $Camel__ < ActiveRecord::Base

  $hobo_model_name # Don't put anything above this

  fields do
@foreach columns
    @perl @_l=($tm{$type}); foreach(@$rails_flags) { push @_l, ":$_"; }
    @perl push @_l, ":index => ".Ruby::as_literal($index) if defined $index;
    @perl foreach(keys %$rails_map) { push @_l, ":$_ => ".Ruby::as_literal($rails_map->{$_}); };
    @perl $_f = join(', ', @_l);
    $_\t$_f
@end
  end
$rails_extra

end

