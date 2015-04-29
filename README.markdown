# `dungeon-ats`

This repository contains a small "port" of my [Dungeon][dun] project
(originally implemented in Java) to [ATS][ats].

This ATS version of the project is missing many essential features.
For example, it contains no network code at all, so every universe
can only be played in single-player. In this sense it is more of a
standard text-adventure game engine.

## Universe file format

`dungeon-ats` supports a very simple universe file format (unlike
the original Dungeon's YAML format). Each space is specified by
exactly seven fields. Each field takes up exactly one line.
The fields must be in the following order:

    id
    id_of_northern_exit
    id_of_eastern_exit
    id_of_southern_exit
    id_of_western_exit
    space_name
    space_description

Thus every `.universe` file must have a number of lines that is
a multiple of seven.

Important note: `dungeon-ats` expects that one space have the
id `spawn`, which is the space that the player will start the game
in.


[dun]: https://github.com/abreen/Dungeon
[ats]: http://www.ats-lang.org
