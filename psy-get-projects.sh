#!/usr/bin/env bash

function psy_get_projects() {
	{ #helpers
		_help() {
			cat <<-EOF
				$(printf "\e[1m%s\e[0m" "Get-psy-projects")

				$(printf "\e[1;4m%s\e[0m" "Usage:")
				  get-psy-projects [--options]

				$(printf "\e[1;4m%s\e[0m" "Options:")
				  -h, --help             <boolean?>      Display this help information.
				  -a, --all              <boolean?>      Enable download All projects.
				  -d, --directory        <string?>       Set Directory path value. (Default: "~/installations")
				  -g, --git              <boolean?>      Enable get Git repository instead of Tarball.
				  -i, --install          <boolean?>      Enable Install project in Path.
				  -l, --list             <boolean?>      Enable List projects.
				  -p, --project          <string>       Set Project value.
				  -r, --root-password    <string?>       Set Root-Password value.
				  -t, --token            string>        Set Github Token value.

				$(printf "\e[1;4m%s\e[0m" "Examples:")
				  get-psy-projects -p "bash-library" -d "~/installations" t "ghp_123..."

				  get-psy-projects \ 
				    --project "bash-library" \ 
				    --directory "~/installations" \ 
				    --token "ghp_123..."

				  get-psy-projects --all --git --install

			EOF

			# set -- "${__}"
			# set -- "|" "${@//$'\n'/$'\n'"| "}" "|"
			# echo "${@//$'\n'/"   | "$'\n'}"

			exit 0
		}

		config_parse_args() {
			((${#})) || _help

			while getopts ":-:had:gilp:r:t:" opt; do
				case "${opt}" in
				h) _help ;;
				a) all="1" ;;
				g) git="1" ;;
				i) install="1" ;;
				l) list="1" ;;
				d) directory="${OPTARG}" ;;
				p) project="${OPTARG}" ;;
				r) arg_root_password="${OPTARG}" ;;
				t) arg_git_token="${OPTARG}" ;;
				-)
					case "${OPTARG}" in
					help) _help ;;
					all) all="1" ;;
					git) git="1" ;;
					install) install="1" ;;
					list) list="1" ;;
					directory) directory="${!OPTIND:?"Option \"--${OPTARG}\" requires an argument."}" && ((OPTIND++)) ;;
					project) project="${!OPTIND:?"Option \"--${OPTARG}\" requires an argument."}" && ((OPTIND++)) ;;
					root-password) arg_root_password="${!OPTIND:?"Option \"--${OPTARG}\" requires an argument."}" && ((OPTIND++)) ;;
					token) arg_git_token="${!OPTIND:?"Option \"--${OPTARG}\" requires an argument."}" && ((OPTIND++)) ;;
					*) throw_error "Unknown long option: \"--${OPTARG}\"" ;;
					esac
					;;
				:) throw_error "Option \"-${OPTARG:-}\" requires an argument." ;;
				?) throw_error "Invalid option \"-${OPTARG:-}\"" ;;
				*) throw_error "Unknown option \"-${OPTARG:-}\"" ;;
				esac
			done
			shift "$((OPTIND - 1))"

			((${#})) &&
				: "${*}" &&
				throw_error "${_:+$'\n'}    Invalid arguments: ${_:+$'\n'}      \"${_// /\"$'\n      \"'}\""
		}

		throw_error() {
			printf "\n\e[2;31m%s %s\e[0m\n\n" \
				"❌[${BASH_SOURCE[-1]##*/}] ERROR:" "${1:-}"

			exit "${2:-1}"
		}
	}

	{ #utilities
		pgp__psy_get_projects() {
			{ #helpers
				get_github_tarball() {
					{ #helpers
						_help() {
							cat <<-EOF
								$(printf "\e[1m%s\e[0m" "Get_github_tarball")

								$(printf "\e[1;4m%s\e[0m" "Usage:")
								  get_github_tarball [--options]

								$(printf "\e[1;4m%s\e[0m" "Options:")
								  -h, --help      <boolean?>      Display this help information.
								  -o, --owner     <string>       Set Owner value.
								  -r, --repo      <string>       Set Repo value.
								  -t, --token     <string>       Set Token value.
								  -O, --output    <string>       Set Output path directory value.

								$(printf "\e[1;4m%s\e[0m" "Examples:")
								  get_github_tarball -o "psy" -r "bash-library" -t "ghp_123..." -O "./lib"

								  get_github_tarball \ 
								    --owner "psy" \ 
								    --repo "bash-library" \ 
								    --token "ghp_123..." \ 
								    --output "./lib"

							EOF

							exit 0
						}

						config_parse_args() {
							((${#})) || _help

							while ((${#})); do
								arg="${1:-}" val="${2:-}" && shift

								case "${arg}" in
								-h | --help) _help ;;
								-o | --owner) owner="${val:?"Option \"${arg}\" requires an argument."}" && shift ;;
								-r | --repo) repo="${val:?"Option \"${arg}\" requires an argument."}" && shift ;;
								-t | --token) token="${val:?"Option \"${arg}\" requires an argument."}" && shift ;;
								-O | --output) path_output_directory="${val:?"Option \"${arg}\" requires an argument."}" && shift ;;
								*) throw_error "Unknown option \"${arg}\"" ;;
								esac
							done
						}
					}

					{ #utilities
						run_get_github_tarball() {
							{ #helpers
								http_request() {
									if [[ -n "${token}" ]]; then
										curl \
											--header "Accept: application/vnd.github+json" \
											--header "Authorization: Bearer ${token}" \
											--header "X-GitHub-Api-Version: 2022-11-28" \
											--location "${url}" \
											--output "${path_tmp_output_tar_file}" \
											--write-out "%{http_code}" \
											--silent
									else
										curl \
											--header "Accept: application/vnd.github+json" \
											--header "X-GitHub-Api-Version: 2022-11-28" \
											--location "${url}" \
											--output "${path_tmp_output_tar_file}" \
											--write-out "%{http_code}" \
											--silent
									fi
								}
							}

							{ #utilities
								run_request() {
									if ((http_response_code == 200)); then
										tar \
											--extract \
											--gzip \
											--strip-components=1 \
											--directory "${path_output_directory}" \
											--file "${path_tmp_output_tar_file}" ||
											throw_error "Failed to extract tarball from \"${path_tmp_output_tar_file}\" to \"${path_output_directory}\""

										printf "\e[93m%s  \e[96m\"%s\"\n" \
											$'\n'"Info:" "Tarball downloaded and extracted successfully from Github" \
											"Path:" "${path_output_directory}" \
											"Url: " "github.com/${owner}/${repo}"

										printf "\e[0m\n\n"

										if type tree &>/dev/null; then
											tree --dirsfirst "${path_output_directory}"
										else
											ls -hasl --color "${path_output_directory}"
										fi

										du -hs "${path_output_directory}"

										rm -fr "${path_tmp_output_directory}"

										return 0
									else
										printf "\e[91m%s  \e[95m\"%s\"\n" \
											$'\n'"ERROR:" "Failed get Tarball from Github" \
											"Code: " "${http_response_code}" \
											"Url:  " "${url}"

										[[ -s "${path_tmp_output_tar_file}" ]] && cat "${path_tmp_output_tar_file}"

										rm -fr "${path_tmp_output_directory}"

										return 1
									fi
								}
							}

							{ #variables
								declare -i http_response_code="${http_response_code:+0}"

								declare \
									url="${url:+}" \
									path_tmp_output_directory="${path_tmp_output_directory:+}" \
									path_tmp_output_tar_file="${path_tmp_output_tar_file:+}"
							}

							{ #setting-variables
								[[ -d "${path_output_directory}" ]] || mkdir -p "${path_output_directory}"

								{ # url
									printf -v "url" "https://%s/%s/%s/%s" \
										"api.github.com/repos" \
										"${owner}" \
										"${repo}" \
										"tarball"
								}

								{ # path_tmp_output_directory
									path_tmp_output_directory="$(mktemp --directory -t "get_github_tarball.XXXXXX")"
								}

								{ # path_tmp_output_tar_file
									path_tmp_output_tar_file="${path_tmp_output_directory}/${repo}.tar.gz"
								}

								{ # http_response_code
									http_response_code="$(http_request)"
								}
							}

							:

							run_request || throw_error "Failed to get tarball from Github"
						}
					}

					{ #variables
						declare \
							owner="${owner:+}" \
							repo="${repo:+}" \
							token="${token:+}" \
							path_output_directory="${path_output_directory:+}"
					}

					{ #setting-variables
						config_parse_args "${@}"

						type curl &>/dev/null || throw_error "command \"curl\" is required"

						[[ -n "${owner}" ]] || throw_error "option \"--owner\" is required"
						[[ -n "${repo}" ]] || throw_error "option \"--repo\" is required"
						[[ -n "${path_output_directory}" ]] || throw_error "option \"--output\" is required"

						: || { # debug
							printf "\e[92m%s\n" \
								$'\n\n' \
								$'\e[2;92m[DEBUG]\e[0;92m '"${FUNCNAME[0]^}()" \
								"    owner:      \"${owner}\"" \
								"    repo:       \"${repo}\"" \
								"    token:      \"${token}\"" \
								"    output:     \"${path_output_directory}\"" \
								$'\e[0m'
						}
					}

					:

					run_get_github_tarball
				}

				get_github_repo() {
					{ #helpers
						_help() {
							cat <<-EOF
								$(printf "\e[1m%s\e[0m" "Get_github_repo")

								$(printf "\e[1;4m%s\e[0m" "Usage:")
								  get_github_repo [--options]

								$(printf "\e[1;4m%s\e[0m" "Options:")
								  -h, --help      <boolean?>      Display this help information.
								  -o, --owner     <string>       Set Owner value.
								  -r, --repo      <string>       Set Repo value.
								  -t, --token     <string>       Set Token value.
								  -O, --output    <string>       Set Output path directory value.

								$(printf "\e[1;4m%s\e[0m" "Examples:")
								  get_github_repo -o "psy" -r "bash-library" -t "ghp_123..." -O "./lib"

								  get_github_repo \ 
								    --owner "psy" \ 
								    --repo "bash-library" \ 
								    --token "ghp_123..." \ 
								    --output "./lib"

							EOF

							exit 0
						}

						config_parse_args() {
							((${#})) || _help

							while ((${#})); do
								arg="${1:-}" val="${2:-}" && shift

								case "${arg}" in
								-h | --help) _help ;;
								-o | --owner) owner="${val:?"Option \"${arg}\" requires an argument."}" && shift ;;
								-r | --repo) repo="${val:?"Option \"${arg}\" requires an argument."}" && shift ;;
								-t | --token) token="${val:?"Option \"${arg}\" requires an argument."}" && shift ;;
								-O | --output) path_output_directory="${val:?"Option \"${arg}\" requires an argument."}" && shift ;;
								*) throw_error "Unknown option \"${arg}\"" ;;
								esac
							done
						}
					}

					{ #utilities
						run_get_github_repo() {
							{ #utilities
								ggr__git_clone_repo() {
									printf "\e[2;96m"

									git clone "${ggr__url}" "${path_output_directory}"

									if [[ -f "${path_output_directory}/${repo}.sh" ]]; then
										pushd "${path_output_directory}" &>/dev/null || throw_error "Failed to pushd"

										printf "\n"

										pwd
										ls -hasl
										chmod +x "${path_output_directory}/${repo}.sh"

										printf "\n\n"

										popd &>/dev/null || throw_error "Failed to popd"
									fi
								}
							}

							{ #variables
								declare \
									ggr__url="${ggr__url:+}"
							}

							{ #setting-variables
								[[ -d "${path_output_directory}" ]] || mkdir -p "${path_output_directory}"

								{ # ggr__url
									printf -v "ggr__url" "https://%s@%s/%s/%s.%s" \
										"${token}" \
										"github.com" \
										"${owner}" \
										"${repo}" \
										"git"
								}
							}

							:

							ggr__git_clone_repo
						}
					}

					{ #variables
						declare \
							owner="${owner:+}" \
							repo="${repo:+}" \
							token="${token:+}" \
							path_output_directory="${path_output_directory:+}"
					}

					{ #setting-variables
						config_parse_args "${@}"

						type git &>/dev/null || throw_error "command \"git\" is required"

						[[ -n "${owner}" ]] || throw_error "option \"--owner\" is required"
						[[ -n "${repo}" ]] || throw_error "option \"--repo\" is required"
						[[ -n "${path_output_directory}" ]] || throw_error "option \"--output\" is required"

						: || { # debug
							printf "\e[92m%s\n" \
								$'\n\n' \
								$'\e[2;92m[DEBUG]\e[0;92m '"${FUNCNAME[0]^}()" \
								"    owner:      \"${owner}\"" \
								"    repo:       \"${repo}\"" \
								"    token:      \"${token}\"" \
								"    output:     \"${path_output_directory}\"" \
								$'\e[0m'
						}
					}

					:

					run_get_github_repo
				}

				print_input() {
					{ #helpers
						_help() {
							cat <<-EOF
								$(printf "\e[1;93m%s\e[0m" "Print_input")

								$(printf "\e[1;4;93m%s\e[0m" "Usage:")
								  print_input [--options]

								$(printf "\e[1;4;93m%s\e[0m" "Options:")
								  -h, --help            <boolean?>      Display this help information.
								  -l, --label           <string?>       Set Label value.
								  -o, --var-output      <string?>       Set Output-Value name variable.
								  -p, --password        <boolean?>      Enable Password mode.
								  -P, --prompt          <string?>       Set Prompt value.
								  -T, --placeholder     <string?>       Set Placeholder value.

								$(printf "\e[1;4;93m%s\e[0m" "Examples:")
								  print_input -l "Login" -P "Username: " -T "Enter your username" -o "username_variable"

								  print_input \ 
								    --label "Login" \ 
								    --prompt "Username" \ 
								    --placeholder "Enter your username" \ 
								    --var-output "username_variable"
							EOF

							exit 0
						}

						config_parse_args() {
							((${#})) || _help

							while ((${#})); do
								arg="${1:-}" val="${2:-}" && shift

								case "${arg}" in
								-h | --help) _help ;;
								-o | --var-output) name_variable_output="${val:?"Option \"${arg}\" requires an argument."}" && shift ;;
								-l | --label) label="${val:?"Option \"${arg}\" requires an argument."}" && shift ;;
								-p | --password) mode_password="1" ;;
								-P | --prompt) prompt="${val:?"Option \"${arg}\" requires an argument."}" && shift ;;
								-T | --placeholder) placeholder="${val:?"Option \"${arg}\" requires an argument."}" && shift ;;
								*) throw_error "Unknown option \"${arg}\"" ;;
								esac
							done
						}
					}

					{ #utilities
						pi__print_input() {
							{ #helpers
								pi__get_input_from_stdin() {
									declare k1 k2 k3

									while :; do
										IFS= read -rsn1 pi__character 2>/dev/null >&2

										read -rsn1 -t 0.0001 k1
										read -rsn1 -t 0.0001 k2
										read -rsn1 -t 0.0001 k3
										pi__character+="${k1}${k2}${k3}"

										[[ -z "${pi__character}" ]] && printf "\e[2K\e[1A\e[2K\e[1A\e[2K\e[0G" && break

										case "${pi__character}" in
										$'\x7f') # backspace
											((${#pi__input_line})) && {
												pi__input_line="${pi__input_line%?}"
												printf "\b \b"

												[[ -z "${pi__input_line}" ]] &&
													printf "%s" "${pi__placeholder}"
											}
											;;
										$'\x0a') : ;;             # enter/return
										$'\x1b') break ;;         # escape
										$'\e[F') : ;;             # end
										$'\e[H') : ;;             # home
										$'\x1b\x5b\x32\x7e') : ;; # insert
										$'\x1b\x5b\x41') : ;;     # up
										$'\x1b\x5b\x42') : ;;     # down
										$'\x1b\x5b\x43') : ;;     # right
										$'\x1b\x5b\x44') : ;;     # left
										$'\x1b\x5b\x35\x7e') : ;; # page up
										$'\x1b\x5b\x36\x7e') : ;; # page down
										*)
											[[ -z "${pi__input_line}" ]] &&
												printf "%s\e[%sD" \
													"${pi__filler_placeholder}" "${#placeholder}"

											pi__input_line+="${pi__character}"

											if ((mode_password)); then
												printf "*"
											else
												printf "%s" "${pi__character}"
											fi
											;;
										esac
									done
								}
							}

							{ #utilities
								pi__build_input_line() {
									[[ -n "${label}" ]] && printf "%s\n" "${pi__label}"
									[[ -n "${prompt}" ]] && printf "%s" "${pi__prompt}"
									[[ -n "${placeholder}" ]] && printf "%s" "${pi__placeholder}"

									pi__get_input_from_stdin

									if [[ -n "${name_variable_output}" ]]; then
										declare -n pi__output="${name_variable_output}"
										[[ -n "${pi__input_line}" ]] &&
											pi__output="${pi__input_line}"
									else
										[[ -n "${pi__input_line}" ]] &&
											printf "%s\n\n" "${pi__input_line}"
									fi
								}
							}

							{ #variables
								declare \
									pi__label="${pi__label:+}" \
									pi__prompt="${pi__prompt:+}" \
									pi__placeholder="${pi__placeholder:+}" \
									pi__input_line="${pi__input_line:+}" \
									pi__character="${pi__character:+}" \
									pi__output="${pi__output:+}"
							}

							{ #setting-variables

								{ # pi__label
									printf -v pi__label "\n\t\e[92m%-10s \e[0m" \
										"${label^}"
								}

								{ # pi__prompt
									printf -v pi__prompt "\n\t\e[96m%-10s : \e[0m" \
										"${prompt^}"
								}

								{ # update placeholder
									if [[ -n "${name_variable_output}" ]]; then
										declare -n pi__output="${name_variable_output}"

										[[ -n "${pi__output}" ]] && {
											placeholder="${pi__output}"
										}
									fi
								}

								{ # pi__placeholder
									printf -v pi__placeholder "\e[38;5;236m%s\e[0m\e[%sD" \
										"${placeholder}" "${#placeholder}"
								}

								{ # pi__filler_placeholder
									printf -v pi__filler_placeholder "%${#placeholder}s" " "
								}
							}

							:

							pi__build_input_line
						}
					}

					{ #variables
						declare -i mode_password="${mode_password:+0}"

						declare \
							name_variable_output="${name_variable_output:+}" \
							label="${label:+}" \
							prompt="${prompt:+}" \
							placeholder="${placeholder:+}"
					}

					{ #setting-variables
						config_parse_args "${@}"

						{ # options
							[[ -n "${placeholder}" ]] || placeholder="Type text..."
						}
					}

					:

					pi__print_input
				}

				:

				normalize_path() {
					declare \
						np__arg_path="${1}" \
						np__path_output="${np__path_output:+}"

					np__normalize_path() {
						[[ "${np__arg_path:0:9}" == "../../../" ]] && {
							: "${PWD%/*}"
							: "${_%/*}"
							np__path_output="${_%/*}/${np__arg_path:9}"
							return
						}

						[[ "${np__arg_path:0:6}" == "../../" ]] && {
							: "${PWD%/*}"
							np__path_output="${_%/*}/${np__arg_path:6}"
							return
						}

						[[ "${np__arg_path:0:3}" == "../" ]] && {
							np__path_output="${PWD%/*}/${np__arg_path:3}"
							return
						}

						[[ "${np__arg_path:0:1}" == "~" ]] && np__path_output="${np__arg_path/\~/${HOME}}" && return

						[[ "${np__arg_path}" =~ ^\.[^/] ]] && np__path_output="${PWD}/${np__arg_path}" && return

						[[ "${np__arg_path:0:1}" == "." ]] && np__path_output="${np__arg_path/\./${PWD}}" && return

						[[ "${np__arg_path:0:1}" != "/" ]] && np__path_output="${PWD}/${np__arg_path}" && return

						[[ "${np__arg_path:0:1}" == "/" ]] && np__path_output="${np__arg_path}" && return
					}

					np__normalize_path

					printf "%s\n" "${np__path_output}"
				}

				check_element_in_index_array() {
					{ #helpers
						_help() {
							cat <<-EOF
								array_utilities::check_element_in_index_array

								Usage:
								  check_element_in_index_array [--options]

								Options:
								  -h, --help                      Display this help information.
								  -n, --name <string>             Set index array name.
								  -e, --element <string>          Set array element to check.

								Examples:
								  check_element_in_index_array -n "index_array_name" -e "item"

								  check_element_in_index_array \ 
								    --name "index_array_name" \ 
								    --element "item"

							EOF

							exit 0
						}

						config_parse_args() {
							while getopts ":-:he:n:" opt; do
								case "${opt}" in
								h) _help ;;
								n) name_iarr_variable="${OPTARG}" ;;
								e) arg_element="${OPTARG}" ;;
								-)
									case "${OPTARG}" in
									help) _help ;;
									name) name_iarr_variable="${!OPTIND:?"Option \"--${OPTARG}\" requires an argument."}" && ((OPTIND++)) ;;
									element) arg_element="${!OPTIND:?"Option \"--${OPTARG}\" requires an argument."}" && ((OPTIND++)) ;;
									*) throw_error "Unknown long option: \"--${OPTARG}\"" ;;
									esac
									;;
								:) throw_error "Option \"-${OPTARG:-}\" requires an argument." ;;
								?) throw_error "Invalid option \"-${OPTARG:-}\"" ;;
								*) throw_error "Unknown option \"-${OPTARG:-}\"" ;;
								esac
							done
							shift "$((OPTIND - 1))"

							if
								[[ -z "${name_iarr_variable}" ]] ||
									[[ -z "${arg_element}" ]]
							then
								_help
							fi
						}
					}

					{ #variables
						declare -i \
							OPTIND="${OPTIND:+0}" \
							tmp_index="${tmp_index:+0}"

						declare \
							name_iarr_variable="${name_iarr_variable:+}" \
							arg_element="${arg_element:+}" \
							ref_name_iarr_variable="${ref_name_iarr_variable:+}"
					}

					{ #setting-variables
						config_parse_args "${@}"

						declare -n ref_name_iarr_variable="${name_iarr_variable}"
					}

					:

					for tmp_index in "${!ref_name_iarr_variable[@]}"; do
						[[ "${ref_name_iarr_variable[${tmp_index}]}" =~ ^"${arg_element}"$ ]] &&
							return 0
					done

					return 1
				}

				print_log_line() {
					declare \
						pgp__arg_left_text="${1:?$'\e[91m[ARG]\e[0m' <Left_text> argument is required.}" \
						pgp__arg_right_text="${2:?$'\e[91m[ARG]\e[0m' <Right_text> argument is required.}"

					declare pgp__filler_text_line="${pgp__filler_text_line:+}"

					:

					: $((COLUMNS - ${#pgp__arg_left_text} - ${#pgp__arg_right_text} - 30))
					printf -v "pgp__filler_text_line" "%${_}s"

					printf "    %s %s %s\n" \
						$'\e[48;5;233;38;5;88m'"  [    ${pgp__arg_left_text}    ]  "$'\e[0m' \
						$'\e[38;5;236m'"${pgp__filler_text_line// /─}"$'\e[0m' \
						$'\e[48;5;233;38;5;226m'"  \"${pgp__arg_right_text^}\"  "$'\e[0m'
				}
			}

			{ #utilities
				pgp__run_psy_get_projects() {
					((list)) && pgp__print_all_projects && exit 0

					for pgp__select_project in "${iarr_pgp__download_projects[@]}"; do
						{ #config
							case "${pgp__select_project}" in
							"ved") pgp__select_project="virtual-env-docker" ;;
							"") continue ;;
							esac

							check_element_in_index_array \
								--name "iarr_pgp__psy_projects" \
								--element "${pgp__select_project}" ||
								throw_error "Project \"${pgp__select_project}\" not found."
						}

						# project \ repo \ directory
						pgp__download_projects \
							"${pgp__select_project}" \
							"${aarr_pgp__psy_projects_repos[${pgp__select_project}]}" \
							"${pgp__path_psy_projects_directory}"
					done
				}

				:

				pgp__print_debug() {
					if ((git)); then
						print_log_line "GET GIT" "${pgp__arg_project//-/ }"
					else
						print_log_line "GET" "${pgp__arg_project//-/ }"
					fi

					printf "           \e[2;96m%s \e[93m\"%s\"\e[0m\n" \
						"Project:   " "${pgp__arg_project}" \
						"Repo:      " "${pgp__arg_repo}" \
						"Directory: " "${pgp__path_repo_installation_directory}" \
						"Token:     " "${token::8}****************"

					printf "\n\n"
				}

				pgp__install_project() {
					((install)) || return 0

					printf "%s\n" "${root_password}" |
						sudo ln -sfv \
							"${pgp__path_repo_installation_directory}/${pgp__arg_project}.sh" \
							"/usr/local/bin/${pgp__arg_project}"
				}

				pgp__print_all_projects() {
					printf "\n\e[2;4;92m%s\e[0m\n\n" "List all Psy-Projects and Repositories:"
					for pgp__select_project in "${iarr_pgp__psy_projects[@]}"; do
						printf "\e[96m%s \e[93m\"%s\"\e[0m\n" \
							"Project: " "${pgp__select_project}" \
							"Repo:    " "${aarr_pgp__psy_projects_repos[${pgp__select_project}]}"

						{ # alias
							case "${pgp__select_project}" in
							"virtual-env-docker") printf "\e[96m%s \e[93m\"%s\"\e[0m\n" "Alias:   " "ved" ;;
							esac
						}

						printf "\n\n"
					done

					exit 0
				}

				pgp__download_projects() {
					{ #config
						declare \
							pgp__arg_project="${1:?$'\e[91m[ARG]\e[0m' <Project> argument is required.}" \
							pgp__arg_repo="${2:?$'\e[91m[ARG]\e[0m' <Repo> argument is required.}" \
							pgp__arg_directory="${3:?$'\e[91m[ARG]\e[0m' <Directory> argument is required.}"

						declare \
							pgp__path_repo_installation_directory="${pgp__path_repo_installation_directory:+}"

						:

						pgp__path_repo_installation_directory="${pgp__arg_directory}/${pgp__arg_repo}"
					}

					:

					pgp__print_debug

					if ((git)); then
						get_github_repo \
							--owner "${pgp__arg_repo%/*}" \
							--repo "${pgp__arg_project}" \
							--token "${token}" \
							--output "${pgp__path_repo_installation_directory}"
					else
						get_github_tarball \
							--owner "${pgp__arg_repo%/*}" \
							--repo "${pgp__arg_project}" \
							--token "${token}" \
							--output "${pgp__path_repo_installation_directory}"
					fi

					pgp__install_project

					printf "\n\n"
				}
			}

			{ #variables
				unset -v \
					iarr_pgp__psy_projects \
					iarr_pgp__download_projects \
					aarr_pgp__psy_projects_repos

				declare \
					pgp__path_psy_projects_directory="${pgp__path_psy_projects_directory:+}" \
					pgp__select_project="${pgp__select_project:+}" \
					pgp__select_repo="${pgp__select_repo:+}"

				declare -a \
					iarr_pgp__download_projects \
					iarr_pgp__psy_projects

				declare -A aarr_pgp__psy_projects_repos
			}

			{ #setting-variables
				pgp__path_psy_projects_directory="$(normalize_path "${directory}")"

				{ # token
					if [[ -n "${arg_git_token}" ]]; then
						token="${arg_git_token}"
					elif [[ "${!PSY*}" ]]; then
						: "${!PSY*}" && token="${!_}"
					else
						print_input \
							--password \
							--label "Enter your Github Token" \
							--prompt "Token" \
							--placeholder "ghp_4CEGFCeycSecc23dasd32dfds5k" \
							--var-output "token"
					fi

					[[ -z "${token}" ]] && throw_error "Token is required."
				}

				{ # root_password
					((install)) &&
						if [[ -n "${arg_root_password}" ]]; then
							root_password="${arg_root_password}"
						elif [[ -n "${ROOT_PASSWORD:-}" ]]; then
							root_password="${ROOT_PASSWORD}"
						else
							print_input \
								--password \
								--label "Enter your Root Password" \
								--prompt "Password" \
								--placeholder "P4s5w0RD" \
								--var-output "root_password"
						fi
				}

				{ # iarr_pgp__psy_projects
					iarr_pgp__psy_projects=(
						"bash-core-library"
						"psy-bash-tools"
						"psy-dev-utilities"
						"bootstrap-ved"
						"virtual-env-docker"
						"psy-get-binaries"
						"ga-utilities"
					)
				}

				{ # aarr_pgp__psy_projects_repos
					aarr_pgp__psy_projects_repos=(
						["bash-core-library"]="psy-projects-bash/bash-core-library"
						["psy-bash-tools"]="psy-projects-bash/psy-bash-tools"
						["psy-dev-utilities"]="psy-projects-bash/psy-dev-utilities"
						["bootstrap-ved"]="psy-projects-bash/bootstrap-ved"
						["virtual-env-docker"]="psy-projects-docker/virtual-env-docker"
						["psy-get-binaries"]="psy-projects-ga/psy-get-binaries"
						["ga-utilities"]="psy-projects-ga/ga-utilities"
					)
				}

				{ # iarr_pgp__download_projects
					if ((all)); then
						iarr_pgp__download_projects=("${iarr_pgp__psy_projects[@]}")
					else
						iarr_pgp__download_projects=("${project}")
					fi
				}
			}

			:

			pgp__run_psy_get_projects
		}
	}

	{ #variables
		declare -i \
			all="${all:+0}" \
			git="${git:+0}" \
			install="${install:+0}" \
			list="${list:+0}"

		declare \
			directory="${directory:+}" \
			project="${project:+}" \
			root_password="${root_password:+}" \
			token="${token:+}" \
			arg_root_password="${arg_root_password:+}" \
			arg_git_token="${arg_git_token:+}"
	}

	{ #setting-variables
		config_parse_args "${@}"

		{ # options
			[[ -n "${directory}" ]] || directory="${HOME}/installations/psy-projects"

			! ((list)) && ! ((all)) && [[ -z "${project}" ]] && throw_error "Option \"--project\" is required."
			((git)) && ! type git &>/dev/null && throw_error "command \"git\" is required"
		}

		: || { # debug
			printf "\e[92m%s\n" \
				$'\n\n' \
				$'\e[2;92m[DEBUG]\e[0;92m '"${FUNCNAME[0]^}()" \
				$'' \
				"    all:                  \"${all}\"" \
				"    git:                  \"${git}\"" \
				"    install:              \"${install}\"" \
				"    list:                 \"${list}\"" \
				"    directory:            \"${directory}\"" \
				"    project:              \"${project}\"" \
				"    root_password:        \"${root_password}\"" \
				"    token:                \"${token}\"" \
				$'\e[0m'
		}
	}

	:

	pgp__psy_get_projects
}

psy_get_projects "${@}"
