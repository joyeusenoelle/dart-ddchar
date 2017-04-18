## D&D Character Generator
### Dart 1.22.1

A D&D random character generator written to learn Dart! ddchar.dart is intended to be run on the command line. It accepts the following flags:

    -m, --mush: Changes the default line break character (for printing) from
        "\n" to "%r" (the line-break sequence used by MUSH and MUD clients)
    -n <name>, --name <name>: Sets the character's name.
    -c <class>, --class <class>: Sets the character's class.
    -r <race>, --race <race>: Sets the character's race.

If *-n*, *-c*, or *-r* are not provided, the script will select or generate them randomly.

The script uses per-class weights to assign attributes (generated using the 4d6-drop-one method), applies racial modifiers, and randomly selects skills, gear, and special abilities where appropriate. It also generates starting gold.

The character is printed to the screen by default. (The ''-m'' flag changes the output to a format suitable for pasting into a MUSH/MUD client.)
