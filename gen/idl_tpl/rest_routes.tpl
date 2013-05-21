@openfile node/AUTO_gen.tmp-append
@// @'{rgx: /(GET):\/(users)\/(\d+)$/i, rgx_key: '_default_rgx_key', permfn: 'perm_the_same_user', dbfn: 'db_1_by_pk', cols: ["name"] },
@// @'{rgx: /(GET):\/(conferences)\/(\d+)$/i, rgx_key: '_default_rgx_key', permfn: 'perm_conference_owner_or_host', dbfn: 'db_1_by_pk', cols: ["name","access_config"] },
@foreach columns
    @perl foreach $my_rest (@$rest) { my $cn = "_${my_rest}_cols"; push @{$cn}, "\"$_\""; }
@end
@foreach rest_routes
    @perl my $cn="_${_}_cols"; ${$cn} = join(',', @{$cn}); my $fl = ($flags?", flags: ".to_json($flags, {}):'');
{$pattern, cols: [${$cn}]$fl},
@end
@// bit of a hack but we need to clear these out ... maybe store the arrays as a hash of references ...
@foreach columns
    @perl foreach $my_rest (@$rest) { my $cn = "_${my_rest}_cols"; @{$cn} = (); }
@end
