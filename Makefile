.PHONY: run copyIns install test tail completion
run:
	zig build run

copyIns:install
	cp -v ./zig-out/bin/m ~/.local/bin/

install:
	zig build install --release=safe
test:
	zig build test --summary all --verbose

tail:
	tail -f ~/.config/z_math/.zmath | bat --paging=never --file-name=log

completion:
	./zig-out/bin/m completion > /usr/share/bash-completion/completions/m
