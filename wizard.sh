#!/usr/bin/env bash
# shellcheck disable=SC2221,SC2222
set -euo pipefail
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="$__dir/${BASH_SOURCE[0]}"
readonly __dir __file

# BASH-WIZARD: a very-light implementation of Ansible in pure bash
# https://github.com/thomvaill/bash-wizard
# 
# A task consists of the following bash functions:
#  - [required] task_name.do()  : implementation of the task, if possible in an idempotent way
#  - [optional] task_name.when(): to decide when the task has to run; useful for non-idempotent implementations or tasks that are too long to run everytime (eg. those which involve a download)
#  - [optional] task_name.undo(): implementation of the task rollback
#
# vvv YOUR PLAYBOOK vvv

install_skaffold.when() {
    ! command -v skaffold &> /dev/null
}
install_skaffold.do() {
    curl -Lo /tmp/skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-darwin-arm64
    sudo mv /tmp/skaffold /usr/local/bin/skaffold
}
install_skaffold.undo() {
    sudo rm -f /usr/local/bin/skaffold
}

configure_something.do() {
    echo "test" > ~/test
}
configure_something.undo() {
    rm -f ~/test
}

# ^^^^^^^^^^^^^^^^^^^^^
# STOP!
# Here starts the library
# Do not edit from there
#

usage() {
    cat << END
Usage:
    ${BASH_SOURCE[0]} [args] <action>

Actions:
    apply     : execute all the tasks
    rollback  : undo all the tasks
    list      : list all the tasks

Arguments:
    -h|--help : display this help
    --debug   : enable debug mode (eg. output tasks' commands)
END
}

_get_tasks() {
    local my_functions my_function task line
    local tasks_ordered_by_name=()

    my_functions="$(compgen -A function)"
    for my_function in ${my_functions}
    do
        if echo "${my_function}" | grep '\.do$' &> /dev/null
        then
            # shellcheck disable=SC2001
            task="$(echo "${my_function}" | sed 's/\.do$//')"
            tasks_ordered_by_name+=("${task}")
        fi
    done

    while read -r line
    do
        if echo "${line}" | grep '^.*\.do\s*(' &> /dev/null
        then
            for task in "${tasks_ordered_by_name[@]}"
            do
                if echo "${line}" | grep "^${task}\.do\s*(" &> /dev/null
                then
                    echo "${task}"
                fi
            done
        fi
    done < "${__file}"
}

_function_exists() {
    local name="${1}"
    [[ "$(type -t "${name}")" == "function" ]]
}

_output_start() {
    echo -en "\e[90m"
}

_output_end() {
    echo -en "\e[0m"
}

_apply_task() {
    local task="${1}"

    if ! _function_exists "${task}.do"
    then
        echo "${task}.do() is not implemented"
        return 1
    fi

    echo "🎯 ${task}"

    if _function_exists "${task}.when"
    then
        echo "    > checking if should be run"
        _output_start
        [[ "${WIZARD_DEBUG:-}" = "1" ]] && set -x
        if ! "${task}.when"
        then
            set +x
            _output_end
            echo "    > no need to be run"
            echo "    > ⏭️"
            return 0
        fi
    fi

    echo "    > running"
    _output_start
    [[ "${WIZARD_DEBUG:-}" = "1" ]] && set -x
    "${task}.do"
    set +x
    _output_end
    echo "    > ✅"
}

_rollback_task() {
    local task="${1}"

    echo "🎯 ${task}"

    if ! _function_exists "${task}.undo"
    then
        echo "    > ⚠️ ${task}.undo() is not implemented"
        return 0
    fi

    echo "    > rollbacking"
    _output_start
    [[ "${WIZARD_DEBUG:-}" = "1" ]] && set -x
    "${task}.undo"
    set +x
    _output_end
    echo "    > ✅"
}

_apply() {
    local tasks task
    tasks="$(_get_tasks)"

    for task in ${tasks}
    do
        _apply_task "${task}"
        echo ""
    done

    echo "🎉 apply successful!"
}

_rollback() {
    local tasks task
    tasks="$(_get_tasks)"

    for task in ${tasks}
    do
        _rollback_task "${task}"
        echo ""
    done

    echo "🎉 rollback successful!"
}

_list() {
    _get_tasks
}

main() {
    local params=""

    # parse args and parameters (source: https://medium.com/@Drew_Stokes/bash-argument-parsing-54f3b81a6a8f)
    while (( "$#" ))
    do
        case "${1}" in
            -h|--help)
                usage
                exit 0
                shift
                ;;
            --debug)
                WIZARD_DEBUG=1
                shift
                ;;
            -*|--*=) # unsupported flags
                echo "Error: unsupported flag: ${1}" >&2
                exit 1
                ;;
            *) # preserve positional arguments
                params="${params} ${1}"
                shift
                ;;
        esac
    done
    params="${params:1}"

    case "${params}" in
        apply)
            _apply
            ;;
        rollback)
            _rollback
            ;;
        list)
            _list
            ;;
        "")
            usage
            ;;
        *)
            echo "Error: unsupported parameter: ${params}" >&2
            exit 1
            ;;
    esac
}

main "$@"
