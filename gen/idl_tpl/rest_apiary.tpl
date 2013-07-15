@openfile node/AUTO_apiary.tmp-append
@foreach columns
    @perl foreach $my_rest (@$rest) { my $cn="_${my_rest}_cols"; my $cnv="_${my_rest}_colsv"; push @{$cn}, "$_"; push @{$cnv}, "\"$_\": " . (($type eq 'integer') ? $api_doc->{sample} : "\"$api_doc->{sample}\""); }
@end
@foreach rest_routes
    @perl my $cn="_${_}_cols"; ${$cn} = join(',', @{$cn});
    @perl my $cnv="_${_}_colsv"; ${$cnv} = '{' . join(',', @{$cnv}) . '}';

$api_doc->{description}

    @perl if ($api_doc->{signature} =~ /^GET/) {
Retrieve specified columns only by appending query string 'c' parameter, e.g. ?c=${$cn}

Access required to execute this API will be documented shortly.
$api_doc->{signature}
> Authorization: Basic N2NiNTI0ZmI2NGViNGUyNmQxYjIzM2QyZjI5M2QxMGM6
< 200
< Content-Type: application/json; charset=utf-8
${$cnv}
+++++
< 401
< Content-Type: application/json; charset=utf-8
{"error":{"code": 401,"text": "HTTP Basic Auth or Cookie Session Required" }}
+++++
< 403
< Content-Type: application/json; charset=utf-8
{"error":{"code":403,"text":"Access Denied"}}
    @perl } elsif ($api_doc->{signature} =~ /^DELETE/) {
Access required to execute this API will be documented shortly.
$api_doc->{signature}
> Authorization: Basic N2NiNTI0ZmI2NGViNGUyNmQxYjIzM2QyZjI5M2QxMGM6
< 200
< Content-Type: application/json; charset=utf-8
{}
+++++
< 401
< Content-Type: application/json; charset=utf-8
{"error":{"code": 401,"text": "HTTP Basic Auth or Cookie Session Required" }}
+++++
< 403
< Content-Type: application/json; charset=utf-8
{"error":{"code":403,"text":"Access Denied"}}
    @perl } elsif ($api_doc->{signature} =~ /^POST/) {
Access required to execute this API will be documented shortly.
$api_doc->{signature}
> Authorization: Basic N2NiNTI0ZmI2NGViNGUyNmQxYjIzM2QyZjI5M2QxMGM6
> Content-Type: application/json; charset=utf-8
${$cnv}
< 201
< Content-Type: application/json; charset=utf-8
{}
+++++
< 401
< Content-Type: application/json; charset=utf-8
{"error":{"code": 401,"text": "HTTP Basic Auth or Cookie Session Required" }}
+++++
< 403
< Content-Type: application/json; charset=utf-8
{"error":{"code":403,"text":"Access Denied"}}
    @perl } elsif ($api_doc->{signature} =~ /^PUT/) {
Access required to execute this API will be documented shortly.
$api_doc->{signature}
> Authorization: Basic N2NiNTI0ZmI2NGViNGUyNmQxYjIzM2QyZjI5M2QxMGM6
> Content-Type: application/json; charset=utf-8
${$cnv}
< 200
< Content-Type: application/json; charset=utf-8
{}
+++++
< 401
< Content-Type: application/json; charset=utf-8
{"error":{"code": 401,"text": "HTTP Basic Auth or Cookie Session Required" }}
+++++
< 403
< Content-Type: application/json; charset=utf-8
{"error":{"code":403,"text":"Access Denied"}}
    @perl }
@end
@// bit of a hack but we need to clear these out ... maybe store the arrays as a hash of references ...
@foreach columns
    @perl foreach $my_rest (@$rest) { my $cn="_${my_rest}_cols"; my $cnv="_${my_rest}_colsv"; @{$cn} = (); @{$cnv} = (); }
@end
