
IDL_DIR=idl
TPL_DIR=idl_tpl

DEP_v1=cdn_root/v1
DEP_co=cdn_root/v1/AUTO/conference_options.js
DEP_aa=node/AUTO_routes.js
DEP_ag=node/AUTO_gen.tmp
DEP_2clean=$(DEP_co) rails/my/app/models/*

all: main $(DEP_co) $(DEP_v1) $(DEP_aa)

main $(DEP_aa): ./schema/main.sch
	rm -f $(DEP_ag)
	$(IDL_DIR)/idl <$^
	(echo "var _r=[" && cat $(DEP_ag) && echo && echo "];" && echo "module.exports=_r;") | cat >$(DEP_aa)

$(DEP_co): ./schema/conference_options.sch
	(echo -n 'var _br_v1_conference_options=' && $(IDL_DIR)/idl -j <$^) | cat >$@

$(DEP_v1): $(DEP_co)
	$(MAKE) -C $@

clean:
	$(MAKE) -C $(DEP_v1) clean
	rm -f $(DEP_2clean) $(DEP_co) $(DEP_aa) $(DEP_ag)

