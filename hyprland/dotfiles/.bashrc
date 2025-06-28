# RHMD
# Realist Hyperland Minimal Desktop LTO & GPO version
# .bashrc file -> ~/.bashrc
# (c) 2024

[[ $- != *i* ]] && return

LS_COLORS='di=1;35:fi=0:ln=31:pi=5:so=5:bd=5:cd=5:or=31:mi=0:ex=35:*.rpm=90:*.png=35:*.gif=36:*.jpg=35:*.c=92:*.jar=33:*.py=93:*.h=90:*.txt=94:*.doc=104:*.docx=104:*.odt=104:*.csv=102:*.xlsx=102:*.xlsm=102:*.rb=31:*.cpp=92:*.sh=92:*.html=96:*.zip=4;33:*.tar.gz=4;33:*.mp4=105:*.mp3=106'
PS1="\[$(tput bold)\]\[$(tput setaf 1)\][\[$(tput setaf 3)\]\u\[$(tput setaf 2)\]@\[$(tput setaf 4)\]\h \[$(tput setaf 5)\]\W\[$(tput setaf 1)\]]\[$(tput setaf 7)\]\\$ \[$(tput sgr0)\]"

export LS_COLORS
export PS1
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=$HOME/.config/rofi/scripts:$PATH
export GTK_THEME=Adwaita-dark
export XDG_RUNTIME_DIR=/run/user/$UID
export EIX_LIMIT=0
export MANPATH="/usr/local/man:$MANPATH"
export LANG=cs_CZ.UTF-8
export TERM=xterm-256color
export EDITOR=nano
export HISTSIZE=1000
export HISTFILESIZE=2000
export HISTCONTROL=ignoredups:erasedups
export VISUAL=subl

ex ()
{
  if [ -f $1 ] ; then
    case $1 in
      *.7z)        7z x $1      ;;
      *.bz2)       bunzip2 $1   ;;
      *.gz)        gunzip $1    ;;
      *.rar)       unrar x $1   ;;
      *.tar)       tar xf $1    ;;
      *.tar.bz2)   tar xjf $1   ;;
      *.tar.gz)    tar xzf $1   ;;
      *.tar.xz)    tar xf $1    ;;
      *.tar.zst)   unzstd $1    ;;
      *.tbz2)      tar xjf $1   ;;
      *.tgz)       tar xzf $1   ;;
      *.Z)         uncompress $1;;
      *.zip)       unzip $1     ;;
      *)           echo "'$1' cannot be extracted via ex()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

alias cc="clear"
alias df="df -h"
alias mkd="mkdir -pv"
alias grep="grep --color=auto"

alias cp="cp -i"
alias mv="mv -i"
alias rm="rm -i"

alias nf="neofetch"

alias ls='eza -al --color=always --group-directories-first'
alias la='eza -a --color=always --group-directories-first'
alias ll='eza -l --color=always --group-directories-first'
alias lt='eza -aT --color=always --group-directories-first'

alias pinstall="sudo emerge -av"
alias premove="sudo emerge -av --unmerge"
alias update="sudo emerge -uDU @world"
alias clean="sudo emerge --depclean"
alias sync="sudo emerge --sync"

alias art="php artisan"
alias server="php artisan serve"