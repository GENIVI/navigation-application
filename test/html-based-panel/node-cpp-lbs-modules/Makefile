all: clean configure.release build pack

release: configure.release build pack install

debug: configure.debug build pack install

configure.%:
	@node-gyp configure --$*

build:
	@node-gyp build

pack:
	npm pack

install:	
	cd .. ; npm install node-cpp-lbs-modules/node-cpp-lbs-modules-0.1.0.tgz

clean:
	@node-gyp clean

.PHONY: build
