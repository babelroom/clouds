
VAR_DIR=/var/estream
INSTALL_DEST=/usr/local/estream

# disable implicit make rules 
.SUFFIXES:

all: bin/estream

clean:

install: all
	install -d $(INSTALL_DEST) 
	cp -R ./bin $(INSTALL_DEST)
	cp -R ./conf $(INSTALL_DEST)
	install -d $(VAR_DIR) 
	cp -R ./data $(VAR_DIR)
	cp -R ./log $(VAR_DIR)
	cp ./bin/rc /etc/init.d/estream
	/sbin/chkconfig --add estream

purge_install:
	-/etc/init.d/estream stop
	rm -rf $(INSTALL_DEST)
	rm -rf $(VAR_DIR)


