
2gen=br_api.min.js br_api.full.min.js
2delete=src/tmp.min.js
DEP_wraprtc=src/wraprtc/wraprtc.js
DEP_socket_io=src/socket.io.min.js

all: c/gen.min.js $(2gen)

c/gen.min.js:
	$(MAKE) -C ./c

phony:

$(DEP_wraprtc): phony
	test -d src/wraprtc || (cd src && git clone https://github.com/babelroom/wraprtc.git)
	test -d src/wraprtc && (cd src/wraprtc && git pull)

br_api.full.min.js: src/tmp.min.js $(DEP_wraprtc) $(DEP_socket_io)
	/bin/cat $^ > $@

br_api.min.js: src/js_fixups.js src/br_api.js
	/bin/cat $^ | uglifyjs > $@

src/tmp.min.js: src/js_fixups.js src/br_api.js src/br_api.streaming.js src/br_api.logic.js src/br_api.controllers.js
	/bin/cat $^ | uglifyjs > $@

clean:
	$(MAKE) -C ./c clean
	rm -f $(2gen) $(2delete)

