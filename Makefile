SHELL=/bin/bash

# Variables
BIN = ./node_modules/.bin
COFFEE = coffee # Assume global
BROWSERIFY = ${BIN}/browserify # assume local?
UGLIFY = ${BIN}/uglifyjs # assume local?
DAEMON = ./scripts/watch.sh

# Targets
default: web

deps: 
	if test -d "node_modules"; then echo "dependencies installed"; else npm install; fi
	
clean:
	@echo -e "Starting Clean ..."  
	if [ -e "lib/pxl.js" ]; then rm lib/pxl.js; fi
	if [ -e "lib/pxl.min.js" ]; then rm lib/pxl.min.js; fi
	rm -rf build
	@echo -e "Finished Clean \xE2\x98\x95 \n"

modules = $(shell find src -name '*.coffee')

concat: ${modules}
	@$(foreach module,$(modules),(cat $(module); echo) >> lib/pxl.coffee;)

# compile the NPM library version to JavaScript
build: clean
	@echo -e "Starting Build ..."  
	${COFFEE} -o build/ src
	${COFFEE} -o html/js examples
	#cp -r build/* lib/coffeegl/.
	@echo -e "Finished Build \xE2\x98\x95 \n"

# Watch a directory then hit web build
watch: clean
	${DAEMON} make
	
# compiles the NPM version files into a combined minified web .js library
web: build
	@echo -e "Starting Web Build ..."  
	${BROWSERIFY} build/pxl.js > build/pxl.js
	${UGLIFY} build/pxl.js > build/pxl.min.js
	@echo -e "Finished Web Build \xE2\x98\x95 \n"

docs:
	@echo -e "Starting Building Docs ..."  
	docco src/*.coffee
	@echo -e "Finished Building Docs \xE2\x98\x95 \n"

website:
	@echo -e "Starting Building Website ..."  
	python3 scripts/tachikoma.py -s html

test: build
	mocha --compilers coffee:coffee-script

dist: deps web

publish: dist
	npm publish
