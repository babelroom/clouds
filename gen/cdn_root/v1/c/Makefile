
2gen=css/gen_workspace.css ws_js/gen.min.js gen-other1.min.js gen-other2.min.js gen.min.js
#2gen=css/gen_lobby.css css/gen_lobby_old_ie.css css/gen_workspace.css ws_js/gen.min.js gen-other1.min.js gen-other2.min.js gen.min.js
DEP_gen_lobby=lobby/customized.css lobby/br_override.css css/widget.css recurly-js/recurly-customized.css
DEP_gen_lobby_old_ie=lobby/app.css lobby/br_override.css css/widget.css recurly-js/recurly-customized.css
# TODO .. minify gen_workspace ...
DEP_gen_workspace=css/html5-doctor-reset.css css/babelroom.css jquery/css/ui.jqgrid.css css/widget.css
#DEP_gen_workspace=jquery/css/ui.jqgrid.css css/widget.css
#DEP_gen_workspace=jquery/css/ui.jqgrid.css css/babelroom.css css/widget.css
DEP_gen_preminified=css/jquery-ui-1.10.1.custom.min.css fo/css/br_icons.css icon_foo_adj.css

# in order of inclusion ... but pre-minified are separated out
DEP_gen_jquery_base_min_js=
#DEP_gen_other1_js=wraprtc/wraprtc.js jquery/js/jquery-1.9.1.js jquery/js/i18n/grid.locale-en.js -- temporarily remove wraprtc
DEP_gen_other1_js=jquery/js/jquery-1.9.1.js jquery/js/i18n/grid.locale-en.js
#DEP_gen_jquery_min_js=jquery/js/jquery.jqGrid.min.js jquery/js/jquery.tools.min.js jquery/js/jquery-ui-1.8.23.custom.min.js
DEP_gen_jquery_min_js=jquery/js/jquery.jqGrid.min.js jquery/js/jquery-ui-1.10.1.custom.min.js jquery/js/query.tools.scrollable-1.2.7.min.js
DEP_gen_other2_js=jquery/js/jquery.placeholder.js flash/swfobject.js
# changed ws_js/comet.js to ws_js/br_comet_sio.js in order to enable comet
#DEP_gen_ws_js=ws_js/br_comet_sio.js ws_js/br_dashboard.js ws_js/br_commands.js ws_js/br_utils.js ws_js/br_invitees.js ws_js/br_overlays.js 
DEP_gen_ws_js=ws_js/br_dashboard.js ws_js/br_commands.js ws_js/br_utils.js ws_js/br_invitees.js ws_js/br_overlays.js \
    ws_js/br_widgets.js ws_js/br_conference.js ws_js/br_content.js ws_js/br_participants.js ws_js/br_dynamic.js ws_js/br_toolbar.js \
	 ../AUTO/conference_options.js
#    ws_js/br_widgets.js ws_js/br_conference.js ws_js/javascripts/prototype.js ws_js/javascripts/window.js ws_js/application.js


all: $(2gen)

css/gen_lobby.css: $(DEP_gen_lobby)
	/bin/cat $^ > $@

css/gen_lobby_old_ie.css: $(DEP_gen_lobby_old_ie)
	/bin/cat $^ > $@

css/gen_workspace.css: $(DEP_gen_preminified) $(DEP_gen_workspace)
	/bin/cat $^ > $@

gen-other1.min.js: $(DEP_gen_other1_js)
	/bin/cat $^ | uglifyjs > $@

gen-other2.min.js: $(DEP_gen_other2_js)
	/bin/cat $^ | uglifyjs > $@

ws_js/gen.min.js: $(DEP_gen_ws_js)
	/bin/cat $^ | uglifyjs > $@

#gen.min.js: jquery/js/jquery-1.9.1.js gen-other1.min.js $(DEP_gen_jquery_min_js) gen-other2.min.js ws_js/gen.min.js 
gen.min.js: $(DEP_gen_jquery_base_min_js) gen-other1.min.js $(DEP_gen_jquery_min_js) gen-other2.min.js ws_js/gen.min.js
	/bin/cat $^ > $@

clean:
	rm -f $(2gen)

