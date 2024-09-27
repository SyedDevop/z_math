copyIns:install
	cp -v ./zig-out/bin/m ~/.local/bin/

install:
	zig build install --release=small

test:
	zig build test --summary all --verbose
