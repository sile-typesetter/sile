#!/bin/sh
touch NEWS README AUTHORS THANKS ChangeLog # HATE YOU GNU
autoreconf --install
sed 's/core//g' configure > config.cache; mv config.cache configure ; chmod +x configure
