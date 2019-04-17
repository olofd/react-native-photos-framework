SHELL := /bin/bash

all:
	NODE_PATH="../../../../nODE_modules/" babel --presets babel-preset-react-native -d out src
	for f in out/*.js; do echo "// @generated" >> $$f; done

watch:
	NODE_PATH="../../../../nODE_modules/" babel --watch --presets babel-preset-react-native -d out src
