#!/bin/bash
# LIAUH - Script Execution Engine (prompts, validation, execution)

# Prompt a single question with type validation
# Returns answer on stdout
_prompt_by_type() {
    local question="$1" type="$2" default="$3" answer

    while true; do
        if [[ -n "$default" ]]; then
            printf "  %b%s%b [%b%s%b]: " "$C_CYAN" "$question" "$C_RESET" "$C_GREEN" "$default" "$C_RESET" >&2
        else
            printf "  %b%s%b: " "$C_CYAN" "$question" "$C_RESET" >&2
        fi
        read -r answer
        [[ -z "$answer" ]] && answer="$default"

        case "$type" in
            yes/no|yesno)
                if [[ "${answer,,}" =~ ^(y|yes|n|no)$ ]]; then
                    [[ "${answer,,}" =~ ^(y|yes)$ ]] && answer="yes" || answer="no"
                    break
                fi
                printf "  %b%s%b\n" "$C_RED" "Please answer yes/no" "$C_RESET" >&2
                ;;
            number)
                if [[ "$answer" =~ ^[0-9]+$ ]]; then break; fi
                printf "  %b%s%b\n" "$C_RED" "Please enter a valid number" "$C_RESET" >&2
                ;;
            *)
                if [[ -n "$answer" ]]; then break; fi
                printf "  %b%s%b\n" "$C_RED" "Cannot be empty" "$C_RESET" >&2
                ;;
        esac
    done
    echo "$answer"
}

# Collect prompt answers from YAML config, then run the script
execute_action() {
    local script="$1" action_index="$2"
    local script_path=$(yaml_script_path "$script")
    local needs_sudo=$(yaml_info "$script" "needs_sudo")
    local parameter=$(yaml_action_param "$script" "$action_index")
    local aname=$(yaml_action_name "$script" "$action_index")

    [[ ! -f "$script_path" ]] && { menu_error "Script not found: $script_path"; return 1; }
    [[ ! -x "$script_path" ]] && chmod +x "$script_path" 2>/dev/null

    # Collect prompt answers
    local prompt_count=$(yaml_prompt_count "$script" "$action_index")
    [[ -z "$prompt_count" || "$prompt_count" == "null" ]] && prompt_count=0
    local -a answers=()
    local -a varnames=()

    if (( prompt_count > 0 )); then
        echo ""
        separator
        echo "  Configuration for: ${aname}"
        separator
        echo ""

        for ((i=0; i<prompt_count; i++)); do
            local question=$(yaml_prompt_field "$script" "$action_index" "$i" "question")
            local ptype=$(yaml_prompt_field "$script" "$action_index" "$i" "type")
            local default=$(yaml_prompt_field "$script" "$action_index" "$i" "default")
            local varname=$(yaml_prompt_var "$script" "$action_index" "$i")

            local answer=$(_prompt_by_type "$question" "$ptype" "$default")

            if [[ -n "$varname" && "$varname" != "null" ]]; then
                varnames+=("$varname")
            fi
            answers+=("$answer")
        done
        echo ""
    fi

    # Confirm before execution
    menu_confirm "Execute '${aname}' now?" || {
        return 1
    }

    # Execute
    echo ""
    separator
    echo "  Executing: ${script} → ${aname}"
    separator
    echo ""

    # Build comma-separated parameter string
    # Format: action,DOMAIN=value,SSL=value,...
    local param_string="$parameter"
    
    for ((i=0; i<${#varnames[@]}; i++)); do
        param_string+=",${varnames[$i]}=${answers[$i]}"
    done

    local exit_code=0
    if [[ "$needs_sudo" == "true" ]]; then
        # Execute with sudo - password cached by sudo itself
        # Script receives full parameter string and must parse it
        sudo bash "$script_path" "$param_string" || exit_code=$?
    else
        bash "$script_path" "$param_string" || exit_code=$?
    fi

    echo ""
    separator
    (( exit_code == 0 )) && echo "  ✅ Completed successfully" || echo "  ❌ Failed (exit code: $exit_code)"
    echo ""
    read -rp "  Press Enter..."
    return $exit_code
}
