#!/bin/bash

set -e

[ "$(id -u)" -ne 0 ] && exit 1

usage ()
{
cat <<EOF
Usage: $0 <args>
Script must be run as root!

Args:
    --home | -H		Specify home directory
    --help | -h		See this message
    --bash | -b		Install powerline for Bash (update .bashrc)
    --tmux | -t		Install powerline for tmux (update .tmux.conf)

    --vim  | -v   <out dir/file>
        Install powerline for VIM (.vimrc by default)
EOF
}

bashrc_upd ()
{
    cat <<EOF >> "${1:-$HOMEDIR/.bashrc}"
# Powerline support for bash

export TERM="xterm-256color"
powerline-daemon -q
POWERLINE_BASH_CONTINUATION=1
POWERLINE_BASH_SELECT=1
. $POWERLINE_PATH/bash/powerline.sh
EOF
}

tmuxconf_upd ()
{
    cat <<EOF >> "${1:-$HOMEDIR/.tmux.conf}"
source $POWERLINE_PATH/tmux/powerline.conf
set-option -g default-terminal screen-256color
EOF 
}

vimrc_upd ()
{
    cat <<EOF >> "${1:-$HOMEDIR/.vimrc}"
\" Poweline support settings

set rtp+=$POWERLINE_PATH/vim/
set laststatus=2
set showtabline=1
set t_Co=256
EOF
}

HOMEDIR="$HOME"
TEMPDIR="$(mktemp -d)" && cd $TEMPDIR

apt update
apt install -y python3 python3-pip git vim tmux
pip3 install git+git://github.com/Lokaltog/powerline

wget https://github.com/powerline/powerline/raw/develop/font/PowerlineSymbols.otf
wget https://github.com/powerline/powerline/raw/develop/font/10-powerline-symbols.conf

mv PowerlineSymbols.otf /usr/share/fonts/
mv 10-powerline-symbols.conf /etc/fonts/conf.d/

cd -

fc-cache -vf /usr/share/fonts/

PYTHON_PATH="$(pip3 show powerline-status | grep -m1 Location | awk '{print $2}')"
POWERLINE_PATH="$PYTHON_PATH/powerline/bindings/"

for arg in "$@"; do
    case $arg in
        --home|-H)
            shift 1
            $HOMEDIR="$1"
	        shift 1 ;;
        --bash|-b)
            [ "$BASH_DONE" == "1" ] || bashrc_upd && BASH_DONE=1
	        shift 1 ;;
        --vim|-v)
            [ "$VIM_DONE" == "1" ] || {
                output_path="$(realpath -q "$2" 2>/dev/null)" && {
                    if [ -d "$output_path" ] ; then
                        vimrc_upd "$output_path/powerline.vim"
                    elif [ -d "$(dirname "$output_path")" ] ; then
                        vimrc_upd "$output_path"
                    fi ; shift 1
                } || vimrc_upd && VIM_DONE=1
            }
            shift 1 ;;
        --tmux|-t)
            [ "$TMUX_DONE" == "1" ] || tmuxconf_upd && TMUX_DONE=1
            shift 1 ;;
     esac
done
