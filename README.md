# Ivor
The steam powered Idris package manager

## Getting started

Ivor currently doesn't ship prebuilt binaries, so you'll have to install the 
dependencies and build it manually:

```
git clone https://github.com/ziman/lightyear.git 
cd lightyear 
git checkout dbcd847ed7a9e62fa0b502b3d89cca43a96f256c 
idris --install lightyear.ipkg 
cd .. 

git clone https://github.com/emptyflash/tomladris.git 
cd tomladris 
git checkout ec324128ebe8b446e84d8be60b0ed085d07fd36d 
idris --install tomladris.ipkg 
cd .. 

git clone https://github.com/emptyflash/idris-ipkg-parser 
cd idris-ipkg-parser 
git checkout 35cc2f54d4f3b3710f637d0a8c897bfbb32fe183 
idris --install ipkgparser.ipkg 
cd ..

idris --build ivor.ipkg
mv ivor.run /usr/local/ivor
```

Next you can create an ivor.toml file in the root of your project 
that looks something like this:
```
name = "ivor"
version = "1.0.0"
description = "The steam powered Idris package manager"

opts = "-p effects -p contrib"
main = "Ivor"
executable = "ivor.run"
sourceDirectory = "src"

[dependencies]
ziman/lightyear = "dbcd847ed7a9e62fa0b502b3d89cca43a96f256c"
emptyflash/tomladris = "ec324128ebe8b446e84d8be60b0ed085d07fd36d"
emptyflash/idris-ipkg-parser = "35cc2f54d4f3b3710f637d0a8c897bfbb32fe183"
```

The dependencies look like user/repo = "git sha". Right now it doesn't 
support transitive dependencies, so you'll have to flatten out your deps 
and make sure they're in the right order. All the other flags match up with 
Idris' ipkg file.

Once you have an ivor.toml you can run

`ivor install` to install the dependencies,
`ivor build` to build your project,
`ivor repl` to hop in the repl with all of your dependencies,
`ivor test` to run the tests.


If you have any problems please open an issue!
