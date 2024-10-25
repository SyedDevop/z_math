run:
	zig build run

copyIns:install
	cp -v ./zig-out/bin/m ~/.local/bin/

install:
	zig build install --release=small

test:
	zig build test --summary all --verbose

tail:
	tail -f ~/.config/z_math/.zmath | bat --paging=never --file-name=log
