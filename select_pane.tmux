#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
default_bind_key='f'
default_preview_pane='true'
default_fzf_window_position='center,70%,80%'
default_fzf_preview_window_position='right,,,nowrap'
default_tmux_list_panes_format='#{session_name}  #{window_index}:#{window_name}  #{pane_index}:#{pane_title}  #{pane_current_command}'

# User overridable options
tmux_bind_key="@fzf_pane_switch_bind-key"
tmux_preview_pane="@fzf_pane_switch_preview-pane"
tmux_fzf_window_position="@fzf_pane_switch_window-position"
tmux_fzf_preview_window_position="@fzf_pane_switch_preview-pane-position"
tmux_list_panes_format="@fzf_pane_switch_list-panes-format"

get_tmux_option() {
    local option="${1}"
    local default_value="${2}"
    local option_override
    option_override="$(tmux show-option -gqv "${option}")"
    if [ -z "${option_override}" ]; then
        echo "${default_value}"
    else
        echo "${option_override}"
    fi
}

shell_quote() {
    local value="${1}"

    printf "'"
    while [[ "${value}" == *"'"* ]]; do
        printf "%s'\\''" "${value%%\'*}"
        value="${value#*\'}"
    done
    printf "%s'" "${value}"
}

set_switch_pane_bindings() {
    local bind_key preview_pane fzf_window_position fzf_preview_window_position list_panes_format
    local run_shell_command
    bind_key="$(get_tmux_option "${tmux_bind_key}" "${default_bind_key}")"
    preview_pane="$(get_tmux_option "${tmux_preview_pane}" "${default_preview_pane}")"
    fzf_window_position="$(get_tmux_option "${tmux_fzf_window_position}" "${default_fzf_window_position}")"
    fzf_preview_window_position="$(get_tmux_option "${tmux_fzf_preview_window_position}" "${default_fzf_preview_window_position}")"
    list_panes_format="$(get_tmux_option "${tmux_list_panes_format}" "${default_tmux_list_panes_format}")"

    run_shell_command="$(shell_quote "${CURRENT_DIR}/select_pane.sh")"
    run_shell_command+=" $(shell_quote "${preview_pane}")"
    run_shell_command+=" $(shell_quote "${fzf_window_position}")"
    run_shell_command+=" $(shell_quote "${fzf_preview_window_position}")"
    run_shell_command+=" $(shell_quote "${list_panes_format}")"

    # Escape '#' so tmux does not expand #{...} format variables in the run-shell
    # argument — they must reach select_pane.sh literally so list-panes -aF can
    # expand them per-pane at runtime.
    run_shell_command="${run_shell_command//'#'/##}"

    tmux bind-key "${bind_key}" run-shell "${run_shell_command}"
}

set_switch_pane_bindings
