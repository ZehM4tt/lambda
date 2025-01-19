#!/bin/bash
rm -rf publish
mkdir publish

mkdir publish/gamemodes
mkdir publish/gamemodes/lambda

cp -R backgrounds/ publish/gamemodes/lambda/backgrounds/
cp -R gamemode/ publish/gamemodes/lambda/gamemode/
cp -R content/* publish/
cp -R entities/ publish/gamemodes/lambda/entities/
cp -R data/ publish/data_static/

cp addon.json publish/addon.json
cp icon24.png publish/gamemodes/lambda/icon24.png
cp logo.png publish/gamemodes/lambda/logo.png
cp lambda.txt publish/gamemodes/lambda/lambda.txt
cp changelog.md publish/gamemodes/lambda/changelog.txt