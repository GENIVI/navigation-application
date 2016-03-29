all: clean configure.release build pack

release: configure.release build pack

debug: configure.debug build pack

configure.%:
	@node-gyp configure --$*

build:
	@node-gyp build

pack:
	npm pack

clean:
	@node-gyp clean

.PHONY: build
