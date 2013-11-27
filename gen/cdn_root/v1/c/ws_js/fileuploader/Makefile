2gen=gen.min.js

#2gen=gen.css gen.min.js
# DEP_gen_css=../../css/jquery-ui-1.10.1.custom.css jquery.fileupload-ui.css style.css -- doesn't work (has relative paths)

DEP_gen_js=jquery-1.6.4.js jquery-ui.1.8.16.js jquery.tmpl.js jquery.iframe-transport.js jquery.fileupload.js jquery.fileupload-ui.js

all: $(2gen)

gen.css: $(DEP_gen_css)
	/bin/cat $^ > $@

gen.min.js: $(DEP_gen_js)
	/bin/cat $(DEP_gen_js) | uglifyjs >> $@

clean:
	rm -f $(2gen)

