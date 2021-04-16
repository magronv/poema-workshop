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

__discovery_found=0
__discovery_total=0
__discovery_explore=""

######################################################
# Discovery mode
######################################################

lsbin="$(which ls)"

parse_new_dir() {
    local ind

    __discovery_found=0
    __discovery_total=0
    __discovery_explore=""

    for i in "${created_dicts[@]}"; do
        unset "$i"
    done

    unset file_list
    unset name
    unset parent_dir
    unset parent_dir_ind
    unset encountered
    unset created_dicts

    unset parent_dict
    unset parent_ind
    unset cur_dir
    unset root_dir


    declare -g -a file_list
    declare -g -a name
    declare -g -a parent_dir
    declare -g -a parent_dir_ind
    declare -g -a encountered
    declare -g -a created_dicts

    declare -g parent_dict=""
    declare -g parent_ind=""
    declare -g cur_dir=""
    declare -g root_dir="$(pwd)"


    cd "${1}"
    __discovery_explore="$(pwd)"

    echo ${__discovery_explore}

    while read line; do
        file_list+=("$line")
        name+=("$(basename "$line")")
        parent_dir+=("$(dirname "$line")")
        encountered+=(0)

        if [ -d "${line}" ]; then
            eval "declare -a -g children_of_${ind}"
            created_dicts+=( "children_of_${ind}" )
        fi

        if [ "${line}" != "$(pwd)" ]; then
            get_index "$(dirname "$line")"
            if [ "$?" -eq "1" ]; then
                echo "[Bullshit] Orphan file found: ${line} " >&2
                exit 1
            fi
            eval "${parent_dict}+=("${ind}")"
            parent_dir_ind+=("${parent_ind}")
        fi

        (( ind++ ))
        (( __discovery_total++ ))
    done < <(find "$(pwd)")

    cur_dir=0
    encountered[0]=1
    (( __discovery_found++ ))

    if [ -z "${__discovery_explore}" ]; then
        PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] (no_dir)\$ '
    else
        PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] (${__discovery_explore}: ${__discovery_found} / ${__discovery_total})\$ '
    fi
}

get_index() {
    parent_dict=""
    for i in "${!file_list[@]}"; do
        if [[ "${file_list[$i]}" = "$1" ]]; then
            parent_dict="children_of_${i}"
            parent_ind="${i}"
            return 0
        fi
    done

    return 1
}

reveal() {
    local cind="$1"
    local hidden="$2"

    if [ -d "${file_list[$cind]}" ]; then
        declare array_ref="children_of_${cind}[@]"
        declare -a tmpdict=( "${!array_ref}" )
        for child in "${tmpdict[@]}"; do
            if [[ "${name[$child]}" != .* ]] || [ ! -z "${hidden}" ]; then
                if [ "${encountered[$child]}" -eq "0" ]; then
                    encountered[$child]=1
                    (( __discovery_found++ ))
                fi
            fi
        done
    fi

    if [ -z "${__discovery_explore}" ]; then
        PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] (no_dir)\$ '
    else
        PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] (${__discovery_explore}: ${__discovery_found} / ${__discovery_total})\$ '
    fi
}

display_file() {
    local cind="$1"
    local prefix="$2"

    if [ -d "${file_list[$cind]}" ]; then
        echo -e "${prefix}${ilblue}${name[$cind]}${ilnormal}"
    elif [ -x "${file_list[$cind]}" ]; then
        echo -e "${prefix}${ilgreen}${name[$cind]}${ilnormal}"
    elif file "${file_list[$cind]}" | grep -qE 'image|bitmap'; then
        echo -e "${prefix}${ilmagenta}${name[$cind]}${ilnormal}"
    else
        echo -e "${prefix}${name[$cind]}"
    fi
}

print_tree() {
    local cind="$1"
    local oprefix="$2"
    local nprefix="$3"

    if [ "${encountered[$cind]}" -eq "1" ]; then
        display_file "$cind" "${oprefix}${nprefix}"
    fi

    if [ "$nprefix" = "├── " ]; then
        oprefix="${oprefix}|   "
    elif [ "$nprefix" = "└── " ]; then
        oprefix="${oprefix}    "
    fi

    if [ -d "${file_list[$cind]}" ]; then
        declare array_ref="children_of_${cind}[@]"
        declare -a tmpdict=( "${!array_ref}" )
        for child in "${tmpdict[@]}"; do
            if [ "${child}" = "${tmpdict[-1]}" ]; then
                print_tree "$child" "$oprefix" "└── "
            else
                print_tree "$child" "$oprefix" "├── "
            fi
        done
    fi
}

show_found() {
    print_tree "0" "" ""
}

function ls() {
    "$lsbin" $@ || return $?

    local hidden=""
    local index=""

    if ( [[ "$@" == *"-a"* ]] || [[ "$@" == *"--all"* ]] ) ; then
        hidden=1
    fi

    if [[ "${@: -1}" == "-"* ]]; then
        get_index "$(pwd)" && index="${parent_ind}"
    else
        local pdir="$(pwd)"
        cd "${@: -1}"
        get_index "$(pwd)" && index="${parent_ind}"
        cd "$pdir"
    fi

    if [ ! -z "${index}" ]; then
        reveal "${index}" ${hidden}
    fi
}

if [ -z "${__discovery_explore}" ]; then
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] (no_dir)\$ '
else
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] (${__discovery_explore}: ${__discovery_found} / ${__discovery_total})\$ '
fi

help_discovery() {
    echo -e """Discovery Module
================

The objective is to discover all file contained in given directory. To do so, use ${ilred}cd${ilnormal}, ${ilred}ls${ilnormal} and ${ilred}pwd${ilnormal} commands to explore the tree view.

To (re)start the games, use:

parse_new_dir path/to/directory/to/explore

Number of total files to find is given in the prompt as such as the number of files already found.  To get an overview of the found files use:

show_found

And to print this message again:

help_discovery

Please be careful when parsing new directory, the parse_new_dir commands performs a full in depth scan of your tree view rooted at the given argument.
"""
}

help_discovery
