echo "Building z_math"

zig build install --release=small

cp -v ./zig-out/bin/m.exe ~/app/bin/
