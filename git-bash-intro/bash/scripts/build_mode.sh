#!/bin/bash

ilblue="\033[01;34m"
ilgray="\033[01;30m"
ilred="\033[01;31m"
ilgreen="\033[01;32m"
ilyellow="\033[01;33m"
ilmagenta="\033[01;35m"
ilcyan="\033[01;36m"
ilwhite="\033[01;37m"
ilbold="\033[01;37m"
ilnormal="\033[0m"

__build_objective_path=""
__build_tree_objective=""

__build_dest_path=""

touchcmd=$(which touch)

new() {
    local new_file="${__build_dest_path}/new.${RANDOM}"

    while [ -e "${new_file}" ]; do
        new_file="${__build_dest_path}/new.${RANDOM}"
    done

    $touchcmd "${new_file}"
}

function touch() {
    new
}

get_absolute_path() {
    local cur_dir="$(pwd)"
    cd "$1"
    echo "$(pwd)"
    cd "${cur_dir}"
}

compare_trees() {
    local src_file="../.a.$RANDOM"
    local dst_file="../.b.$RANDOM"

    tree -F -a -n -f ${__build_objective_path} | sed "s:${__build_objective_path}::g" | sed 's:*::g' > "${src_file}"
    tree -F -a -n -f ${__build_dest_path} | sed "s:${__build_dest_path}::g" | sed 's:*::g' | grep -vE "(${src_file}|${dst_file})" > "${dst_file}"

    diff -y "${src_file}" "${dst_file}"
    rm "${src_file}" "${dst_file}"
}

parse_new_dir() {
    [ "$#" -ne "2" ] && echo "parse_new_dir src_dir obj_dir" >&2 && return 1
    __build_objective_path="$(get_absolute_path "$1")"

    [ ! -e "$2" ] && mkdir "$2"
    __build_dest_path="$(get_absolute_path "$2")"

    cd "${__build_dest_path}"

    echo -e "Objective:\n"
    tree -F -a -n "${__build_objective_path}"
}

help_build() {
    echo -e """Build Module
============

The objective is to reproduce a tree view of files in a minimum number of commands. To do so, use:
    * ${ilred}mkdir${ilnormal}, 
    * ${ilred}cp${ilnormal},
    * ${ilred}mv${ilnormal},
    * ${ilred}rm${ilnormal},
    * and ${ilred}rmdir${ilnormal}.

To (re)start the game, use:

parse_new_dir path/to/directory/to/reproduce path/to/destination/directory

Comparison between the destination directory and the source one can be obtain with command:

compare_trees

The ${ilred}touch${ilnormal} command is modified in such a way that new file is created at root of
the destination directory with random name.

And to print this message again:

help_discovery

Please be careful when parsing new directory, the parse_new_dir commands performs a full in depth scan of your tree view rooted at the given argument.
"""
}

help_build
