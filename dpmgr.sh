#!/usr/bin/env bash
VERSION='1.0.1_00'
export GPG_TTY="$(tty)" #without this gpg dialog doesn't show up
dprint(){
  printf "\e[90m[\e[32mdpmgr\e[90m] \e[0m$1"
}
throwerr(){
  printf "\e[31m[\e[90mdpmgr\e[0;31m] \e[0;1m$1\e[0m\n"
  exit 1
}
help(){
    cat << EOF
[1;32mdpmgr[0m [1m$VERSION[0m
Helper script for managing [32mdpass[0m recipes
[1;92mOptions[0;3;32m:[0;90m
 [32m•[0;1m ls [0;32m──────[0m list entries inside a category
 [32m•[0;1m mkcat [0;32m┬──[0m make new category, works recursively
 [30m╱ ╱ ╱ ╱ [32m└╴[0;90m$[0;1m dpmgr [0;32mmkcat [0memail[90m/[0mpersonal
 [32m•[0;1m mk [0;32m──────[0m make new entry
 [32m•[0;1m v [0;32m───────[0m get entry password
 [32m•[0;1m nts [0;32m─────[0m view entry notes
 [32m•[0;1m ed [0;32m─┬────[0m edit entry
 [30m╱ ╱ ╱ [32m└╴[0;90mfirst line is dpass instructions, anything under is notes
 [32m•[0;1m rm [0;32m──────[0m delete entry
 [32m•[0;1m bakhmut [0;32m— [0;5;1;41;30mDANGER![0m delete category recursively
EOF
exit 1
}
list(){
  set +f
  cd ./$1
  for i in *; do
    [ -d "$i" ]&&printf "\e[1;94m🖿 \e[0;34m"
    [ -f "$i" ]&&printf "\e[1;93m🗝 \e[0;33m"
    printf "$i\e[0m\n"
  done
}
mk(){
  [ -e "$1" ]&&throwerr "$1 already exists."
  dprint "Username\e[90m:\e[32m "
    read user
  dprint "Website\e[90m:\e[32m "
    read website
  dprint "Length\e[90m:\e[32m "
    read length
  printf "\e[42;30m Is everything correct? \e[0m \e[90m[\e[32my\e[0m/\e[31mn\e[90m]\e[0m"
    read check
    check=$(printf "$check"|tr '[:upper:]' '[:lower:]')
    [ "$check" != "y" ]&&exit 0;
  set -x
  echo "$user $website $length"|gpg -c -o "$1"
  set +x
  dprint "To add notes, you can edit the entry.\n"
}

[ -z "$1" ]&&help
[ ! -d ~/.dpmgr ]&&mkdir ~/.dpmgr

cd ~/.dpmgr

#list
case "$1" in
  "ls") list "$2";exit;;
esac
[ -z "$2" ]&&throwerr "You must provide a second argument."
#categories
case "$1" in
  "mkcat")   mkdir -p "$2";exit;;
  "mk")      mk $2;exit;;
  "bakhmut") rm -ri "$2";exit;;
esac
[ ! -f $2 ]&&throwerr "Entry doesn't exist or is a category." 
#now entries
case "$1" in
  "v")
    dprint "Master password:"; read -s DeepDarkMaster;echo
    echo "$DeepDarkMaster"|dpass $(gpg --batch --passphrase "$DeepDarkMaster" -d $2 2>/dev/null|head -n1)|tail -n2;;
  "nts") gpg -d $2 2>/dev/null|tail -n+2;;
  "ed")
    FILENAME=$(mktemp)
    gpg -d $2 2>/dev/null > "$FILENAME"
    ${EDITOR} "$FILENAME"
    gpg --yes -o "$2" -c "$FILENAME"
    head -n1 /dev/urandom > $FILENAME #prevent recovery
    rm "$FILENAME";;
  "rm")  rm -i "$2";;
esac
