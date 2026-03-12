CURRENT_FOLDER=$(pwd)
cd $CONDA_PREFIX/lib/pkgconfig

# Create specific symlinks
ln -sf libcurl.pc libcurl4-openssl-dev.pc 2>/dev/null
ln -sf fontconfig.pc libfontconfig1-dev.pc 2>/dev/null
ln -sf freetype2.pc libfreetype6-dev.pc 2>/dev/null
ln -sf fribidi.pc libfribidi-dev.pc 2>/dev/null
ln -sf libgit2.pc libgit2-dev.pc 2>/dev/null
ln -sf harfbuzz.pc libharfbuzz-dev.pc 2>/dev/null
ln -sf x11.pc libx11-dev.pc 2>/dev/null
ln -sf libxslt.pc libxslt-dev.pc 2>/dev/null

echo "✅ Created symlinks for debian-conda libs compatibility"
cd $CURRENT_FOLDER