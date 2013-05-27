
# only build css here now ...
2gen=css/gen_lobby.css css/gen_lobby_old_ie.css
#2gen=css/gen_lobby.css css/gen_lobby_old_ie.css css/gen_workspace.css

#DEP_gen_lobby=lobby/customized.css lobby/cs_override.css recurly-js/recurly-customized.css
DEP_gen_lobby=lobby/customized.min.css lobby/br_override.css css/widget.css recurly-js/recurly-customized.css
DEP_gen_lobby_old_ie=lobby/app.min.css lobby/br_override.css css/widget.css recurly-js/recurly-customized.css
#DEP_gen_lobby_old_ie=lobby/app.css lobby/cs_override.css recurly-js/recurly-customized.css
#DEP_gen_workspace=jquery/css/ui.jqgrid.css css/babelroom.css css/widget.css # this is no longer used

# -- so then >all this stuff would no longer be used<
# in order of inclusion ... but pre-minified are separated out
DEP_gen_jquery_base_min_js=jquery/js/jquery-1.4.4.min.js
DEP_gen_other1_js=jquery/js/i18n/grid.locale-en.js
DEP_gen_jquery_min_js=jquery/js/jquery.jqGrid.min.js jquery/js/jquery.tools.min.js jquery/js/jquery-ui-1.8.23.custom.min.js
DEP_gen_other2_js=jquery/js/jquery.placeholder.js flash/swfobject.js
DEP_gen_other_min_js=ws_js/socket.io.min.js
# changed ws_js/comet.js to ws_js/br_comet_sio.js in order to enable comet
DEP_gen_ws_js=ws_js/br_comet_sio.js ws_js/cs_dashboard.js ws_js/cs_commands.js ws_js/cs_utils.js ws_js/cs_invitees.js ws_js/cs_overlays.js \
    ws_js/cs_widgets.js ws_js/cs_conference.js
#    ws_js/cs_widgets.js ws_js/cs_conference.js ws_js/javascripts/prototype.js ws_js/javascripts/window.js ws_js/application.js
# -- end of >all this stuff<

# depreciated
# css/buttons.css css/buttons-ie.css css/form.css

all: $(2gen)

css/gen_lobby.css: $(DEP_gen_lobby)
	/bin/cat $^ > $@

css/gen_lobby_old_ie.css: $(DEP_gen_lobby_old_ie)
	/bin/cat $^ > $@

css/gen_workspace.css: $(DEP_gen_workspace)
	/bin/cat $^ > $@

gen-other1.min.js: $(DEP_gen_other1_js)
	/bin/cat $^ | uglifyjs > $@

gen-other2.min.js: $(DEP_gen_other2_js)
	/bin/cat $^ | uglifyjs > $@

ws_js/gen.min.js: $(DEP_gen_ws_js)
	/bin/cat $^ | uglifyjs > $@

#gen.min.js: jquery/js/jquery-1.4.4.min.js gen-other1.min.js $(DEP_gen_jquery_min_js) gen-other2.min.js ws_js/gen.min.js 
gen.min.js: $(DEP_gen_jquery_base_min_js) gen-other1.min.js $(DEP_gen_jquery_min_js) gen-other2.min.js ws_js/gen.min.js $(DEP_gen_other_min_js)
	/bin/cat $^ > $@

clean:
	rm -f $(2gen)

