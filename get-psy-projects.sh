#!/usr/bin/env bash

function config() {
	set -Eeuo pipefail

	declare -g \
		debug="${debug:-0}" \
		trace="${trace:-0}"

	{ # traps
		if ! declare -p __aarr_trap_exit &>/dev/null; then
			# shellcheck disable=SC2016
			declare -rgA __aarr_trap_exit=(
				[trace_caller]='
						declare -i \
							__caller_frame=0

						declare \
							__caller_current_context="${__caller_current_context:-}" \
							__caller_line="${__caller_line:-}" \
							__caller_function="${__caller_function:-}" \
							__caller_file="${__caller_file:-}" \

						declare -a \
							__iarr_caller

						printf "\t\e[35m%s\n" \
							"|    DEBUG: \"Trace Caller\""

						while __caller_current_context=$(caller ${__caller_frame}); do
							unset __iarr_caller

							IFS=" " read -r -a __iarr_caller <<<"${__caller_current_context}"
							set -- "${__iarr_caller[@]}"
							if (( ${#} >= 3 )); then
								declare __caller_line="${1}"
								shift
								declare __caller_function="${1}"
								shift
								declare __caller_file="${*}"
							else
								error_message "caller current context: ${FUNCNAME[0]:-_NoFunction_}" 1
							fi

							((__caller_frame++))

							printf "\e[35m"
							{
								printf "\t%s\n\t%s\n\t%s\n\t%s\n" \
									"|      - Frame ! : ${__caller_frame}" \
									"|      - File ! : ${__caller_file}" \
									"|      - Function ! : ${__caller_function}" \
									"|      - Line ! : ${__caller_line}"
							}  | column -t -s '!' -e
							printf "\t\e[35m%s\e[0m\n" "|"
						done || printf ""

						stty echo
					'
				[trace_bash]='
						declare \
							__trace_variable="${__trace_variable:-}"

						declare -a \
							__iarr_index_trap_exit_trace

						declare -A \
							__aarr_trap_exit_trace

						__iarr_index_trap_exit_trace=(
								source
								function
								line
						)
						__aarr_trap_exit_trace=(
							[source]="BASH_SOURCE"
							[function]="FUNCNAME"
							[line]="BASH_LINENO"
						)

						printf "\t\e[36m%s\n" \
							"|    DEBUG: \"Trace Bash\""

						for __trace_variable in "${__iarr_index_trap_exit_trace[@]}"; do
							declare __var_name="${__trace_variable}"
							declare __var_value="${__aarr_trap_exit_trace[$__trace_variable]}[@]"
							declare -a __iarr_ref_var_value=("${!__var_value:-}")

							declare __color="36"
							declare __elm="${__elm:-}"
							declare -i __counter=0

							for __elm in "${__iarr_ref_var_value[@]}"; do
								if ((__counter == 0)) ; then
									printf "\t\e[${__color}m%s" "|      - ${__var_name^}"
								else
									printf "\t\e[${__color}m%s" "| "
								fi
								printf " ~ %s\e[0m\n" ": ${__elm}"

								((__counter += 1))
							done

							printf "\t\e[${__color}m%s\e[0m\n" "| "
						done   | column -t -s "~"
					'
				[debug]='
						declare \
							__last_exit_code="${?}"

						((__last_exit_code != 0 )) && {
							declare \
								__bash_source="${__bash_source:-}" \
								__bash_funcname="${__bash_funcname:-}" \
								__bash_lineno="${__bash_lineno:-}" \
								__internal_variable="${__internal_variable:-} \
								__divider_bottom="${__divider_bottom:-}

							declare -a \
								__iarr_index_trap_exit_debug_variables
							declare -A \
								__aarr_trap_exit_debug_variables

							if [[ "${FUNCNAME[0]:-_NoFunction_}" == "error_message" ]]; then
								__bash_source="${BASH_SOURCE[1]}"
								__bash_funcname="${FUNCNAME[1]}"
								__bash_lineno="${BASH_LINENO[0]}"
							else
								__bash_source="${BASH_SOURCE[0]:-}"
								__bash_funcname="${FUNCNAME[0]:-_NoFunction_}"
								__bash_lineno="${BASH_LINENO[0]}"
							fi

							__iarr_index_trap_exit_debug_variables=(
									script
									function
									line
									LINENO
									exit_code
							)
							__aarr_trap_exit_debug_variables=(
								[script]="__bash_source"
								[function]="__bash_funcname"
								[line]="__bash_lineno"
								[LINENO]="LINENO"
								[exit_code]="__last_exit_code"
							)

							for __internal_variable in "${__iarr_index_trap_exit_debug_variables[@]}"; do
								declare __var_name="${__internal_variable}"
								declare __var_value="${__aarr_trap_exit_debug_variables[$__internal_variable]}[@]"
								declare -a __iarr_ref_var_value=("${!__var_value:-}")

								declare __color="31"
								declare __elm="${__elm:-}"
								declare -i __counter=0

								for __elm in "${__iarr_ref_var_value[@]}"; do
									if ((__counter == 0)) ; then
										printf "\t\e[${__color}m%s" "|    - ${__var_name^}"
									else
										printf "\t\e[${__color}m%s" "| "
									fi
									printf " ~ %s\e[0m\n" ": ${__elm}"

									((__counter += 1))
								done
							done   | column -t -s "~"

							printf -v __divider_bottom "_%.0s" $(seq 1 "$((COLUMNS / 2))")
							if ((debug)); then
								printf "\t\e[31m%s\e[0m\n" "| "
							else
								printf "\t\e[31m%s\e[0m\n" "|${__divider_bottom}"
							fi

							((trace)) && {
								eval "${__aarr_trap_exit[trace_bash]}"
								eval "${__aarr_trap_exit[trace_caller]}"
								printf "\t\e[31m%s\e[0m\n" "|${__divider_bottom}"
							} || printf ""
						}

						printf "\e[?25h"
						exit "${__last_exit_code}"
					'
			)
		fi

		# shellcheck disable=SC2064
		# trap "${__aarr_trap_exit[debug]}" EXIT ERR
		trap '
				eval "${__aarr_trap_exit[debug]}"
				exit 0
			' EXIT ERR

		trap '
				eval "${__aarr_trap_exit[trace_caller]}"
				exit 0
			' SIGINT
	}

	__old_IFS="${IFS}"
	__custom_IFS=$'\n\t'
	IFS="${__custom_IFS}"
}

function utilities() {
	absolute_path() {
		# generate absolute path from relative path
		# usage:
		#   absolute_path <relative path>
		# example:
		# absolute_path .
		# absolute_path ~
		[[ -z "${1}" ]] && exit 1 || printf ""

		if [ -d "${1}" ]; then
			# dir
			(
				cd "${1}"
				pwd
			) || printf ""
		elif [ -f "${1}" ]; then
			# file
			if [[ ${1} = /* ]]; then
				printf "%s\n" "${1}"
			elif [[ ${1} == */* ]]; then
				printf "%s\n" "$(
					cd "${1%/*}"
					pwd
				)/${1##*/}" || printf ""
			else
				printf "%s\n" "$(pwd)/${1}"
			fi
		fi
	}

	check_directory_exists() {
		# usage:
		#   check_directory_exists "${directory}"

		[[ -z "${1}" ]] && exit 1 || printf ""

		local directory="${1}"

		if [[ -d "${directory}" ]]; then
			printf "%s\n" "${directory}"
		else
			printf "\n\e[91m%s\n  %s\e[0m\n\n\n" \
				"Error:" \
				"Directory does not exisst...  ->  ${directory}" >&2

			exit 1
		fi
	}

	check_directory_exists_or_mkdir() {
		# usage:
		#   check_directory_exists_or_mkdir "${directory}"

		local directory="${1}"

		if [[ -d "${directory}" ]]; then
			printf "%s\n" "${directory}"
		else
			mkdir -p "${directory}"
			printf "%s\n" "${directory}"
		fi
	}

	check_directory_exists_and_rmdir_and_mkdir() {
		# usage:
		#   check_directory_exists_and_rmdir_and_mkdir "${directory}"

		declare directory="${1}"

		if [[ -d "${directory}" ]]; then
			rm -rf "${directory}"
			mkdir -p "${directory}"
			printf "%s\n" "${directory}"
		else
			mkdir -p "${directory}"
			printf "%s\n" "${directory}"
		fi
	}

	join_array_with_separator() {
		[[ -z "${1}" ]] && exit 1 || printf ""

		if [[ -n "${2:-}" ]]; then
			local separator="${1}"
			shift
			local first="${1}"
			shift
			printf "%s" "${first}" "${@/#/${separator}}"
		else
			printf "%s" "NULL"
		fi
	}

	interactive_question() {
		declare -i suggestion="${suggestion:-0}"

		declare \
			title="${title:-}" \
			question="${question:-}" \
			default="${default:-}" \
			prompt="${prompt:-}" \
			reply="${reply:-}" \
			suggestion="${suggestion:-}" \
			is_dry_run_prefix="${is_dry_run_prefix:-}"

		title="${1:-}"
		question="${2:-}"
		default="${3:-}"

		__help() {
			cat <<-__eof_help
				usage:
				  interactive_question <args>
				  ┌─────────────┬────────────┬────────────┐
				  │  Parameter  │    Name    │  Default   │
				  ├─────────────┼────────────┼────────────┤
				  │      1      │  title     │            │
				  │      2      │  question  │            │
				  │      3      │  default   │            │
				  └─────────────┴────────────┴────────────┘

				example:
				  interactive_question "Interactive Question:" "do you want to continue?" "Y"
			__eof_help
		}

		((${force:-0})) && return 0

		if ((${dry_run:-0} == 0)); then
			is_dry_run_prefix=""
		else
			is_dry_run_prefix="[Dry-Run]-"
		fi

		[[ -z "${title:-}" ]] && {
			__help

			exit 0
		}

		if [[ "${default}" = "Y" ]]; then
			prompt="Y/n"
			default="Y"
		elif [[ "${default}" = "N" ]]; then
			prompt="y/N"
			default="N"
		else
			prompt="y/n"
			default=""
		fi
		while true; do
			printf "\n\e[2;95m%s\e[0m\n" \
				"${is_dry_run_prefix}${title}"

			printf "\e[94m%s\e[0m  \e[1;93m[ %s ]\e[0m\n" \
				"    ${question}" "${prompt}"

			((suggestion)) && {
				printf "\n\e[104;97m     %s        \e[0m\n" "Please answer Yes or No."
			} || printf ""

			read -r reply </dev/tty

			if [[ -z "${reply}" ]]; then
				reply="${default}"
			fi

			case "${reply}" in
			Y* | y*) printf "\n" && return 0 ;;
			N* | n*) printf "\n" && return 1 ;;
			*)
				printf "\e[10A"
				suggestion=1
				;;
			esac
		done

		{ # cleaning
			unset -f __help
		}
	}

	gh_get_archive_tarball() {
		local _token="${1}"
		local _user="${2}"
		local _repo="${3}"
		local _output_dir="${4}"

		local _url

		[[ -z "${_token:-}" ]] && {
			cat <<-'get_psy_projects::gh_get_archive_tarball'
				usage:
				  gh_get_archive_tarball <args>
				  ┌─────────────┬─────────────────┐
				  │  Parameter  │   Name          │
				  ├─────────────┼─────────────────┤
				  │      1      │  token          │
				  │      2      │  user           │
				  │      3      │  repo           │
				  │      4      │  output_dir     │
				  └─────────────┴─────────────────┘

				example:
				  gh_get_archive_tarball \
				    "ghp_do1JFasaf2...34tvc45P7Wk" \      # token
				    "psy-projects-bash" \                 # user
				    "bash-core-library" \                 # repo
				    "./src"                               # output_dir

			get_psy_projects::gh_get_archive_tarball

			exit 0
		}

		_url="https://api.github.com/repos/${_user}/${_repo}/tarball/main"

		check_directory_exists "${_output_dir}" >/dev/null

		curl \
			--header "Authorization: token ${_token}" \
			--header "Accept: application/vnd.github.v4.raw" \
			--silent \
			--show-error \
			--fail \
			--location "${_url}" |
			tar \
				--extract \
				--gzip \
				--strip-components=1 \
				--directory "${_output_dir}" \
				--verbose \
				--file -

		# tar -xvzf - --strip-components=1 -C "${output_dir}"

	}

	check_github_token() {
		if [[ -n "${PSY_GITHUB_TOKEN:-}" ]] && ! [[ "${psy_github_token}" =~ ^ghp_.* ]]; then
			psy_github_token="${PSY_GITHUB_TOKEN}"
		fi

		if [[ -z "${PSY_GITHUB_TOKEN:-}" && -f "${path_main_script}/.env" ]]; then
			psy_github_token="$(
				printf "%s\n" "$(<"${path_main_script}/.env")" |
					sed -n 's/gh_token=//p' |
					sed -e 's/^"//' -e 's/"$//'
			)"
		fi

		if [[ -z "${psy_github_token}" ]] || ! [[ "${psy_github_token}" =~ ^ghp_.* ]]; then
			get_token_fron_stdin
		fi

		if [[ -z "${psy_github_token}" ]] || ! [[ "${psy_github_token}" =~ ^ghp_.* ]]; then
			printf "\n\e[91m%s\n  %s\n  \e[93m%s\e[0m\n\n\n" \
				"Error:" \
				"\"PSY_GITHUB_TOKEN\" not set. Please set environment variable." \
				"    ejm. export PSY_GITHUB_TOKEN=\"ghp_34Hf82sdmvXLdsx...\"" >&2

			exit 1
		fi
	}

	check_sudo_require_password() {
		declare \
			check_root_password_in_shadow_file="${check_root_password_in_shadow_file:-}"

		if printf "" | sudo -S cat /etc/shadow; then
			check_root_password_in_shadow_file="$(
				sudo cat /etc/shadow | grep "root" | awk 'BEGIN { FS = ":" } { print $2 }'
			)"

			if (("${#check_root_password_in_shadow_file}" > 2)); then
				return 0
			else
				return 1
			fi
		else
			return 1
		fi
	}

	validate_root_password() {
		declare \
			_root_password="${_root_password:-}"

		_root_password="${1:-}"

		# [[ -z "${_root_password}" ]] && {
		# 	printf "\e[91m%s\e[0m\n" "root_password variable is empty."
		# 	exit 1
		# } || printf ""

		if printf "%s\n" "${_root_password}" |
			sudo -S cat /etc/shadow &>/dev/null; then
			return 0
		else
			return 1
		fi
	}

	get_token_fron_stdin() {
		declare \
			__input_line_content="${__input_line_content:-}"

		printf "\n\e[93m%s\e[0m\n" \
			"Please enter the Github Token:"

		printf "\n\t\e[92m%-10s : \e[0m" \
			"Github Token"

		while IFS= read -r -s -n1 char; do
			[[ -z "${char}" ]] && {
				printf '\n'
				break
			}

			if [[ "${char}" == $'\x7f' ]]; then # backspace was pressed
				((${#__input_line_content} > 0)) && {
					__input_line_content="${__input_line_content%?}"

					printf '\b \b'
				}
			else
				__input_line_content+="${char}"

				printf '*'
			fi
		done

		export psy_github_token="${__input_line_content}"
	}

	get_root_password_from_stdin() {
		declare \
			__input_line_content="${__input_line_content:-}"

		printf "\n\e[93m%s\e[0m\n" \
			"Please enter the password for the root user:"

		printf "\n\t\e[92m%-10s : \e[0m" \
			"Root Password"

		while IFS= read -r -s -n1 char; do
			[[ -z "${char}" ]] && {
				printf '\n'
				break
			}

			if [[ "${char}" == $'\x7f' ]]; then # backspace was pressed
				((${#__input_line_content} > 0)) && {
					__input_line_content="${__input_line_content%?}"

					printf '\b \b'
				}
			else
				__input_line_content+="${char}"

				printf '*'
			fi
		done

		export root_password="${__input_line_content}"
	}

	get_project_from_stdin() {
		declare \
			__input_line_content="${__input_line_content:-}"

		printf "\n\e[93m%s\e[0m\n" \
			"Please enter the project you want to download:"

		printf "\n\t\e[92m%-10s : \e[0m" \
			"Project [user/repo]"

		while IFS= read -r -s -n1 char; do
			[[ -z "${char}" ]] && {
				printf '\n'
				break
			}

			if [[ "${char}" == $'\x7f' ]]; then # backspace was pressed
				((${#__input_line_content} > 0)) && {
					__input_line_content="${__input_line_content%?}"

					printf '\b \b'
				}
			else
				__input_line_content+="${char}"

				printf "%s" "${char}"
			fi
		done

		export set_project="${__input_line_content}"
	}

	show_help() {
		cat <<-get_psy_projects

			${name_main_script}

			Usage:
			  ${name_main_script} [--options]

			Options:
			  -h, --help                     Display this help information.
			  -a, --all                      Get all Psy-Projects.
			  -g, --git                      Clone repos.
			  -d, --directory <value>        Set path download directory [default: cwd].
			  -r, --root-password <value>    Set Root Password.
			  -t, --github-token <value>     Set Token Github.
			  -p, --project <value>          Set download Github Project [user/repo].

			Examples:
			  ${name_main_script} --directory "/home/psy" --root-password "password" --github-token "ghp_do1...XWk"
			  ${name_main_script} --git --all --directory "\${PWD}/installations"
			  ${name_main_script} --project "psy-org/psy-project"

		get_psy_projects

		exit 0
	}

	menu_options() {
		menu_options_utilities() {
			_get_option_value() {
				local _arg="${1:-}"
				local _val="${2}"

				if [[ -n "${_val:-}" ]] && [[ ! "${_val:-}" =~ ^- ]]; then
					printf "%s\n" "${_val}"
				else
					printf "\n\e[91m%s\n  %s\e[0m\n\n\n" \
						"Error:" \
						"${_arg}   ->   Requires a valid argument..." >&2

					exit 1
				fi
			}

			_check_invalid_options() {
				[[ "${#_arr_rest_args[@]}" -gt 0 ]] &&
					[[ "${_arr_rest_args[0]:-}" =~ ^-[!-]?* ]] &&
					{
						printf "\n\e[91m%s\n  %s\e[0m\n" \
							"Error:" \
							"Invalid options..." >&2

						printf "* \e[91m%s\e[0m\n" \
							"${_arr_rest_args[@]}" >&2

						printf "\n\n"

						exit 1
					} || printf ""
			}

			_set_menu_option() {
				local _arr_options
				local _option

				_arr_options=("${@}")

				for _option in "${_arr_options[@]}"; do
					_arr_set_menu_options+=("${_option}")
				done
			}

			_set_menu_option_value() {
				local _arr_option_values
				local _option_value

				_arr_option_values=("${@}")

				for _option_value in "${_arr_option_values[@]}"; do
					_arr_set_menu_options_values+=("${_option_value}")
				done
			}

			_normalize_args() {
				[[ -z "${1}" ]] && exit 1 || printf ""

				while ((${#})); do
					case "${1}" in
					-[!-]?*)
						for ((i = 1; i < ${#1}; i++)); do
							c="${1:i:1}"
							_args+=("-${c}")
						done
						;;
					--?*=*)
						_args+=("${1%%=*}" "${1#*=}")
						;;
					--)
						_args+=(--endopts)
						shift
						_args+=("${@}")
						break
						;;
					*)
						_args+=("${1}")
						;;
					esac

					shift
				done

				set -- "${_args[@]:-}"
			}

			_parse_args() {
				local _case_statement_option="${_case_statement_option:-}"
				local _case_statement_option_value="${_case_statement_option_value:-}"

				local _mktemp_file="${_mktemp_file:-}"
				local _mktemp_file_value_received="${_mktemp_file_value_received:-}"

				local _line_from_mktemp_file

				_mktemp_file="$(mktemp)"
				_mktemp_file_value_received="$(mktemp)"

				_case_statement_option="$(join_array_with_separator " | " "${_arr_set_menu_options[@]}")"
				_case_statement_option_value="$(
					local _option_value
					local _arr_option_values_fixed

					_arr_option_values_fixed=()

					for _option_value in "${_arr_set_menu_options_values[@]}"; do
						_arr_option_values_fixed+=(
							"$(
								printf "%s | %s\n" \
									"${_option_value% | *}" \
									"$(printf '%s' "${_option_value##* | }" | sed 's/ @.*$//')"
							)"
						)
					done

					join_array_with_separator " | " "${_arr_option_values_fixed[@]}"
				)"

				while ((${#})); do
					local _arg="${1:-}"
					local _val="${2:-}"
					shift

					# shellcheck disable=SC2154
					case "${_arg}" in
					-h | --help) _help="1" && break ;;
					--version) printf "%s\n" "[${project_name}] - Version: ${version}" && exit 0 ;;
					esac

					cat <<-_menu_case_template | bash
						case "${_arg}" in
							${_case_statement_option})
								printf "%s\n" "option_only_${_arg}" >>"${_mktemp_file}"
								;;

							${_case_statement_option_value})
								printf "%s@@@%s\n" "option_value_${_arg}"  "${_val:-}" >>"${_mktemp_file}"
								printf "%s" "1" >"${_mktemp_file_value_received}"
								;;

							*)
								[[ "${#_arg}" -gt 0 ]] && {
										printf "%s\n" "_rest_args_${_arg}" >>"${_mktemp_file}"
								} || printf ""
								;;
						esac
					_menu_case_template

					if [[ "$(cat "${_mktemp_file_value_received}")" -eq 1 ]]; then
						(("${#@}" != 0)) && shift || printf ""
						printf "%s" "0" >"${_mktemp_file_value_received}"
					fi
				done

				while read -r _line_from_mktemp_file; do
					if [[ "${_line_from_mktemp_file}" =~ ^option_only_* ]]; then
						local _match_option
						local _get_long_option
						local _check_hyphen_option

						_match_option="$(printf "%s\n" "${_arr_set_menu_options[@]}" | grep "^.*${_line_from_mktemp_file##*_}")"
						_get_long_option="${_match_option##* | }"
						_check_hyphen_option="${_get_long_option//-/_}"

						[[ -n "${_check_hyphen_option}" ]] && {
							export declare "${_check_hyphen_option:2}=1"
						} || printf ""
					fi

					if [[ "${_line_from_mktemp_file}" =~ ^option_value* ]]; then
						local _match_option
						local _grep_match
						local _get_long_option
						local _get_value

						_grep_match="$(printf "%s\n" "${_line_from_mktemp_file}" | sed 's/@@@.*$//')"
						_match_option="$(printf "%s\n" "${_arr_set_menu_options_values[@]}" | grep "^.*${_grep_match##*_}")"

						_get_long_option="${_match_option##* @ }"
						_get_value="$(printf "%s\n" "${_line_from_mktemp_file}" | sed 's/^.*@@@//')"

						export declare "${_get_long_option}=$(_get_option_value "${_get_long_option}" "${_get_value:-}")"

						_args_value_received=1
					fi

					if [[ "${_line_from_mktemp_file}" =~ ^_rest_args_* ]]; then
						[[ -n "${_line_from_mktemp_file}" ]] && {
							_arr_rest_args+=("${_line_from_mktemp_file##_rest_args_}")
						} || printf ""
					fi
				done < <(cat "${_mktemp_file}")

				# printf "_arr_set_menu_options: %s\n" "${_arr_set_menu_options[@]}"
				# printf "_arr_set_menu_options_values: %s\n" "${_arr_set_menu_options_values[@]}"

				# printf "\n\n%s\n" "__________ _mktemp_file __________"
				# cat "${_mktemp_file}"

				rm -f "${_mktemp_file}"
				rm -f "${_mktemp_file_value_received}"
			}
		}

		menu_options_variables() {
			_help="${_help:-0}"
			_args=()
			_args_value_received="${_args_value_received:-0}"

			_arr_set_menu_options=()
			_arr_set_menu_options_values=()

			_arr_rest_args=()
		}

		menu_options_only() {
			_normalize_args "${@}"
			_parse_args "${_args[@]}"
			_check_invalid_options

			((_help)) && show_help || printf ""
		}

		menu_options_utilities
		menu_options_variables
	}

	git_clone_projects() {
		declare \
			select_repo="${select_repo:-}"

		for select_repo in "${iarr_psy_projects[@]}"; do
			declare \
				path_repo_directory="${path_repo_directory:-}" \
				url_github_repo="${url_github_repo:-}"

			path_repo_directory="${path_psy_projects_directory}/${select_repo#*/}"
			url_github_repo="https://${psy_github_token}@github.com/${select_repo}.git"

			{
				printf "\n\e[92m  %s ! \e[93m\"%s\"\e[0m\n" \
					"Project:" "${select_repo#*/}"

				printf "\e[92m  %s ! \e[93m\"%s\"\e[0m\n\n" \
					"Path:" "${path_repo_directory}"
			} | column -t -s "!"

			check_directory_exists_and_rmdir_and_mkdir "${path_repo_directory}" &>/dev/null

			printf "\e[2;91m"
			printf "\n"

			# printf "%s\n" "${url_github_repo}"
			git clone "${url_github_repo}" "${path_repo_directory}"

			printf "\e[0m"

			if [[ -f "${path_repo_directory}/${select_repo#*/}.sh" ]]; then
				pushd "${path_repo_directory}" &>/dev/null

				chmod +x "${path_repo_directory}/${select_repo#*/}.sh"

				PSY_GITHUB_TOKEN="${psy_github_token}" \
					bash "${path_repo_directory}/${select_repo#*/}.sh" --generate-dotenv

				printf "%s\n" "${root_password}" |
					sudo ln -sf \
						"${path_repo_directory}/${select_repo#*/}.sh" \
						"/usr/local/bin/${select_repo#*/}"

				popd &>/dev/null
			fi

			printf "\n\n"
		done
	}

	download_projects() {
		declare \
			select_repo="${select_repo:-}"

		for select_repo in "${iarr_psy_projects[@]}"; do
			declare \
				path_repo_directory="${path_repo_directory:-}"

			path_repo_directory="${path_psy_projects_directory}/${select_repo#*/}"

			{
				printf "\n\e[92m  %s ! \e[93m\"%s\"\e[0m\n" \
					"Project:" "${select_repo#*/}"

				printf "\e[92m  %s ! \e[93m\"%s\"\e[0m\n\n" \
					"Path:" "${path_repo_directory}"
			} | column -t -s "!"

			check_directory_exists_and_rmdir_and_mkdir "${path_repo_directory}" &>/dev/null

			printf "\e[2;91m"
			printf "\n"

			echo hiooo

			gh_get_archive_tarball \
				"${psy_github_token}" \
				"${select_repo%/*}" \
				"${select_repo#*/}" \
				"${path_repo_directory}"

			printf "\e[0m"

			if [[ -f "${path_repo_directory}/${select_repo#*/}.sh" ]]; then
				pushd "${path_repo_directory}" &>/dev/null

				chmod +x "${path_repo_directory}/${select_repo#*/}.sh"

				PSY_GITHUB_TOKEN="${psy_github_token}" \
					bash "${path_repo_directory}/${select_repo#*/}.sh" --generate-dotenv

				printf "%s\n" "${root_password}" |
					sudo ln -sf \
						"${path_repo_directory}/${select_repo#*/}.sh" \
						"/usr/local/bin/${select_repo#*/}"

				popd &>/dev/null
			fi

			printf "\n\n"
		done
	}

	:

	menu_options

}

function variables() {
	_set_menu_option \
		"-a | --all" \
		"-g | --git"

	_set_menu_option_value \
		"-t | --github-token @ set_github_token" \
		"-r | --root-password @ set_root_password" \
		"-d | --directory @ set_path_directory" \
		"-p | --project @ set_project"

	declare -ig \
		all="${all:-0}" \
		git="${git:-0}" \
		help="${help:-0}"

	declare -g \
		path_working_directory="${path_working_directory:-}" \
		path_main_script="${path_main_script:-}" \
		name_main_script="${name_main_script:-}" \
		path_psy_projects_directory="${path_psy_projects_directory:-}" \
		psy_github_token="${psy_github_token:-}" \
		root_password="${root_password:-}" \
		set_project="${set_project:-}"

	declare -ag \
		iarr_psy_projects

}

function setting_variables() {
	set_path_working_directory() {
		[[ -z "${path_working_directory}" ]] && {
			path_working_directory="${PWD}"
		} || printf ""
	}

	set_path_main_script() {
		path_main_script="$(
			cd -P "$(
				dirname "$(
					readlink -f "${BASH_SOURCE[-1]}"
				)"
			)" &>/dev/null && printf "%s\n" "${PWD}"
		)"

		[[ "${path_main_script##*/}" =~ ^src$ ]] && {
			path_main_script="${path_main_script%/*}"
		} || printf ""
	}

	set_name_main_script() {
		name_main_script="$(readlink -f "${BASH_SOURCE[-1]}")"
		name_main_script="${name_main_script##*/}"
	}

	set_path_psy_projects_directory() {
		path_psy_projects_directory="${path_working_directory}"
	}

	set_root_password() {
		if ! check_sudo_require_password; then
			if ! validate_root_password "${root_password}"; then
				get_root_password_from_stdin
			fi
		fi

		if validate_root_password "${root_password}"; then
			printf "\e[2;93m%s\e[0m\n" \
				"The root user password is valid."
		else
			printf "\e[91m%s\e[0m\n" \
				"The root user password is invalid."

			exit 1
		fi
	}

	set_iarr_psy_projects() {
		iarr_psy_projects=(
			"psy-projects-bash/bash-core-library"
			"psy-projects-bash/psy-bash-tools"
			"psy-projects-bash/psy-dev-utilities"
			"psy-projects-bash/bootstrap-ved"
			"psy-projects-docker/virtual-env-docker"
		)
	}

	:

	set_path_working_directory
	set_path_main_script
	set_name_main_script
	set_path_psy_projects_directory
	# set_root_password
	# set_iarr_psy_projects
}

function get_psy_projects() {
	if [[ "${#@}" -gt 0 ]]; then
		menu_options_only "${@}"
	fi

	printf "\n\e[91m%s ........................ \e[93m%s\e[0m\n\n" \
		"[ starting ]" "\"${name_main_script^}\""

	{ # check option-value -d | --directory
		if [[ -n "${set_path_directory:-}" ]]; then
			if ! (check_directory_exists_or_mkdir "${set_path_directory}" &>/dev/null || return 1); then
				check_directory_exists_or_mkdir "${set_path_directory}"
				exit 1
			fi

			path_psy_projects_directory="$(absolute_path "${set_path_directory}")"
		fi
	}

	{ # check option-value -r | --root-password
		if [[ -n "${set_root_password:-}" ]]; then
			root_password="${set_root_password}"

			set_root_password
		else
			set_root_password
		fi
	}

	{ # check option-value -t | --github-token
		if [[ -n "${set_github_token:-}" ]]; then
			psy_github_token="${set_github_token}"
		fi
	}

	{ # check option-value -p | --project
		if [[ -n "${set_project:-}" ]]; then
			iarr_psy_projects=("${set_project}")
		fi
	}

	check_github_token

	printf "\n\e[92m%s \e[96m\"%s\"\e[0m\n" \
		"Psy-Projects-Directory:" "${path_psy_projects_directory}"

	if [[ -z "${set_project}" ]] && ((all == 0)); then
		if interactive_question "Interactive Question:" \
			"Do you want to download all the projects?" \
			"Y"; then
			set_iarr_psy_projects
		else
			get_project_from_stdin

			[[ -n "${set_project}" ]] &&
				iarr_psy_projects=("${set_project}")
		fi
	fi

	if ((git)); then
		git_clone_projects
	else
		download_projects
	fi

	printf "%s\n" "${root_password}" |
		sudo -S ls -hasl /usr/local/bin | grep '\->'
}

function init() {
	config
	utilities
	variables
	setting_variables
	get_psy_projects "${@}"
}

init "${@}"
