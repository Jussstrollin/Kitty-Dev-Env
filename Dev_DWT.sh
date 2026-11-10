#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ProjName="Project"
DIR=""
CompScript=""
Log=""
Editor=""

function PrintHelp() {
    echo -e "Usage : ./Script.sh [-flag ARG] [...]
        Required : 
            -r | --Root : the ABSOLUTE path to project root directory 
            -c | --CompileScript : the ABSOLUTE Path to project Compile Script 
            -l | --LogFile : the ABSOLUTE path to project log file 
            -e | --Editor : the editor command, Preferrably a terminal editor.
        Optional : 
            -n | --Name : the name that will be used for the tabs. 
        Info : 
            -h | --help : prints this message. 
    "
    exit 0
}

if [ $# -eq 0 ]; then
    PrintHelp
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        -r | --Root)
            DIR=$2
            shift 2
            ;;
        -c | --CompileScript)
            CompScript=$2
            shift 2
            ;;
        -l | --LogFile)
            Log=$2
            shift 2
            ;;
        -n | --Name)
            ProjName="$2"
            shift 2
            ;;
        -e | --Editor)
            Editor=$2
            shift 2
            ;;
        -h | --help)
            PrintHelp
            ;;
        *)
            echo "Unknown Option $1"
            exit 1
            ;;
        esac
done

# echo -e "$DIR | $CompScript | $Log | $ProjName"
# exit 5

if [ ! -d "$DIR" ]; then
    echo "$DIR is an invalid directory!"
    exit 2
fi

if [ ! -f "$CompScript" ]; then
    echo "$CompScript is an invalid file!"
    exit 2
fi

if [ ! -x "$CompScript" ]; then
    echo "$CompScript is NOT an executable file!"
    exit 3
fi

if [ ! -f "$Log" ]; then
    echo "$Log is not a valid log file!"
    exit 2
fi

if ! command -v "$Editor" &> /dev/null; then
    echo "$Editor is not a callable editor!"
    exit 4
fi

kitty @ launch \
	--type=tab \
	--title "$ProjName | TERM" \
	--cwd="$DIR" \
	bash -c "clear; echo 'Heres your terminal dawg'; exec bash";

kitty @ launch \
	--type=tab \
	--title "$ProjName | Compiler" \
	--cwd="$DIR" \
	bash -c "clear; $SCRIPT_DIR/Watch_Build.sh $CompScript $DIR; exec bash";

kitty @ launch \
	--type=tab \
	--title "$ProjName | Log view" \
	--cwd="$DIR" \
	bash -c "clear; $SCRIPT_DIR/Watch_Log.sh $Log ; exec bash";

# Set current Tab to the editor
cd "$DIR" || exit 1

echo -ne "\033]0;$ProjName | Editor\007"

($Editor .)
