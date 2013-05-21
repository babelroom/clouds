@openfile cdn_root/v1/generated/$_

@perl sub my_func { local $val = shift; local($f,$k,$v);
@perl   if (ref($val) eq 'ARRAY') { print '['; $f=1; foreach $v(@$val) { print ', ' if !$f; my_func($v); $f=0; }; print ']'; }
@perl   elsif (ref($val) eq 'HASH') { print '{'; $f=1; while(($k, $v) = each(%$val)) { print ', ' if !$f; print '"'.$k.'": '; my_func($v); $f=0; }; print '}'; }
@perl   elsif (JSON::is_bool($val)) { print $val?'true':'false'; }
@perl   elsif (not defined($val)) { print 'null'; }
@perl   elsif ($val=~/^([1-9]|[0-9]\.|[1-9][0-9]+\.)[0-9]+$/) { print $val; }   # currently fails on 1e-10
@perl   else { print '"'.$val.'"'; }
@perl }
@perl print my_func($fields);
@foreach fields
    {
    name: "$_",
    type: "${type}",
    default_value: "${default_value}",
    description: "${description}"
    }
@end

