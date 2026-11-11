#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ProjName="Project"
DIR="Empty"
CompScript="Empty"
Log="Empty"
Editor="Empty"

AiCommand="Empty"
AiSession="Empty"

function PrintHelp() {
    echo -e "Usage : ./Script.sh [-flag ARG...] [...]
        Required : 
            -r | --Root : the ABSOLUTE path to project root directory 
            -c | --CompileScript : the ABSOLUTE Path to project Compile Script 
            -e | --Editor : the editor command, Preferrably a terminal editor.
        Optional : 
            -l | --LogFile : the ABSOLUTE path to project log file 
            -n | --Name : the name that will be used for the tabs. 
            -ai | --AI : the CLI chatbot you want to use, for example : '--AI agy --conversation=3c374e40-b3a0-493d-a4a5-f413d0e11f08'
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
        -ai | --AI)
            AiCommand=$2
            AiSession=$3
            shift 3
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

if [[ $DIR == "Empty" || $CompScript == "Empty" || $Editor == "Empty" ]]; then
    echo "Root, CompScript, or Editor MUST be provided, see -h | --help"
    exit 5
fi

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

if [[ $Log != "Empty" ]]; then
    kitty @ launch \
        --type=tab \
        --title "$ProjName | Log view" \
        --cwd="$DIR" \
        bash -c "clear; $SCRIPT_DIR/Watch_Log.sh $Log ; exec bash";
fi

if [[ $AiCommand != "Empty" ]]; then
    kitty @ launch \
        --type=tab \
        --title "$ProjName | Ai Chat" \
        --cwd="$DIR" \
        bash -c "clear; $AiCommand $AiSession; exec bash";
fi

# Set current Tab to the editor
cd "$DIR" || exit 1

echo -ne "\033]0;$ProjName | Editor\007"

($Editor .)
