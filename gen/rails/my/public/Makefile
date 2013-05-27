
# only build css here now ...
2gen=css/gen_lobby.css css/gen_lobby_old_ie.css

DEP_gen_lobby=lobby/customized.min.css lobby/br_override.css css/widget.css recurly-js/recurly-customized.css
DEP_gen_lobby_old_ie=lobby/app.min.css lobby/br_override.css css/widget.css recurly-js/recurly-customized.css

all: $(2gen)

css/gen_lobby.css: $(DEP_gen_lobby)
	/bin/cat $^ > $@

css/gen_lobby_old_ie.css: $(DEP_gen_lobby_old_ie)
	/bin/cat $^ > $@

css/gen_workspace.css: $(DEP_gen_workspace)
	/bin/cat $^ > $@

clean:
	rm -f $(2gen)

