
IDL_DIR=idl
TPL_DIR=idl_tpl

APIary=../apiary.apib

DEP_v1=cdn_root/v1
DEP_co=cdn_root/v1/AUTO/conference_options.js
DEP_aa=node/AUTO_routes.js
DEP_ag=node/AUTO_gen.tmp
DEP_ap=node/AUTO_apiary.tmp
DEP_vv=node/AUTO_version.js
DEP_2clean=$(DEP_co) rails/my/app/models/*

all: main $(DEP_co) $(DEP_v1) $(DEP_aa) $(DEP_vv) $(APIary)

main $(DEP_aa) $(DEP_ag) $(DEP_ap): ./schema/main.sch
	rm -f $(DEP_ag) $(DEP_ap)
	$(IDL_DIR)/idl <$^
	(echo "var _r=[" && cat $(DEP_ag) && echo && echo "];" && echo "module.exports=_r;") | cat >$(DEP_aa)

$(DEP_co): ./schema/conference_options.sch
	(echo -n 'var _br_v1_conference_options=' && $(IDL_DIR)/idl -j <$^) | cat >$@

$(DEP_v1): $(DEP_co)
	$(MAKE) -C $@

$(APIary): $(DEP_ap) node/apiary.txt node/api.js
	cat node/api.js | perl node/apiary.pl >/tmp/_apiary.pl.out
	cat node/apiary.txt /tmp/_apiary.pl.out $(DEP_ap) | cat >$@
	rm -f /tmp/_apiary.pl.out

$(DEP_vv): ../clouds/misc/version/stamp
	(echo -n "var _version='" && cat $^ | tr -d '\n' && echo -n "." && brrev | tr -d '\n' && echo "';" && echo "module.exports=_version;") | cat >$@

clean:
	$(MAKE) -C $(DEP_v1) clean
	rm -f $(DEP_2clean) $(DEP_co) $(DEP_aa) $(DEP_ag) $(DEP_vv) $(DEP_ap)

