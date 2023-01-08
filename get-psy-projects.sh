#!/usr/bin/env bash

function get_psy_projects() {
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
				  -l, --list             <boolean?>      Enable List projects.
				  -p, --project          <string?>       Set Project value.
				  -r, --root-password    <string?>       Set Root-Password value.
				  -t, --token            string?>        Set Github Token value.

				$(printf "\e[1;4m%s\e[0m" "Examples:")
				  get-psy-projects -agt "ghp_123..." -r "R00tP@ssw0rd" -d "~/installations"

				  get-psy-projects \ 
				    --owner "psy" \ 
				    --repo "bash-library" \ 
				    --token "ghp_123..." \ 
				    --output "./lib"

			EOF

      exit 0
    }

    config_parse_args() {
      ((${#})) || _help

      while getopts ":-:had:glp:r:t:" opt; do
        case "${opt}" in
        h) _help ;;
        a) all="1" ;;
        g) git="1" ;;
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

      ((${#})) && : "${*}" && throw_error "${_:+$'\n'}    Invalid arguments: ${_:+$'\n'}      \"${_// /\"$'\n      \"'}"
    }

    throw_error() {
      : "${BASH_SOURCE[-1]}"
      printf "\n\e[2;31m❌[${_##*/}] ERROR: %s\e[0m\n\n" "${1:-}"
      exit "${2:-1}"
    }
  }

  { #utilities
    gpp__get_psy_projects() {
      { #helpers
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

        get_github_tarball() {
          { #helpers
            _help() {
              cat <<-EOF

								$(printf "\e[1m%s\e[0m" "Get-github-tarball")

								$(printf "\e[1;4m%s\e[0m" "Usage:")
								  get-github-tarball [--options]

								$(printf "\e[1;4m%s\e[0m" "Options:")
								  -h, --help      <boolean?>      Display this help information.
								  -o, --owner     <string?>       Set Owner value.
								  -r, --repo      <string?>       Set Repo value.
								  -t, --token     <string?>       Set Token value.
								  -O, --output    <string?>       Set Output path directory value.

								$(printf "\e[1;4m%s\e[0m" "Examples:")
								  get-github-tarball -o "psy" -r "bash-library" -t "ghp_123..." -O "./lib"

								  get-github-tarball \ 
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
            get_github_tarball() {
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

                { # path_output_directory
                  path_output_directory="$(normalize_path "${path_output_directory}")"

                  [[ -d "${path_output_directory}" ]] || mkdir -p "${path_output_directory}"
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
          }

        }
      }

      { #utilities
        gpp__run_get_psy_projects() {
          { #helpers
            gpp__print_all_projects() {
              printf "\n\e[2;4;92m%s\e[0m\n\n" "List all Psy-Projects and Repositories:"
              for gpp__select_project in "${iarr_gpp__psy_projects[@]}"; do
                printf "\e[96m%s \e[93m\"%s\"\e[0m\n" \
                  "Project: " "${gpp__select_project}" \
                  "Repo:    " "${aarr_gpp__psy_projects_repos[${gpp__select_project}]}"

                printf "\n\n"
              done

              exit 0
            }

            gpp__get_github_reposity() {
              return 1
              declare \
                select_repo="${select_repo:-}"

              for gpp__select_project in "${iarr_gpp__psy_projects[@]}"; do
                declare path_repo_directory="${path_repo_directory:+}"

                gpp__select_repo="${gpp__select_project#*/}"

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
                  pushd "${path_repo_directory}" &>/dev/null || throw_error "Failed to pushd"

                  chmod +x "${path_repo_directory}/${select_repo#*/}.sh"

                  PSY_GITHUB_TOKEN="${psy_github_token}" \
                    bash "${path_repo_directory}/${select_repo#*/}.sh" --generate-dotenv

                  printf "%s\n" "${root_password}" |
                    sudo ln -sf \
                      "${path_repo_directory}/${select_repo#*/}.sh" \
                      "/usr/local/bin/${select_repo#*/}"

                  popd &>/dev/null || throw_error "Failed to popd"
                fi

                printf "\n\n"
              done
            }
          }

          :

          ((list)) && gpp__print_all_projects && exit 0
          ((git)) && gpp__get_github_reposity

          for gpp__select_project in "${iarr_gpp__download_projects[@]}"; do
            { #config
              [[ -z "${gpp__select_project}" ]] && continue

              check_element_in_index_array \
                --name "iarr_gpp__psy_projects" \
                --element "${gpp__select_project}" ||
                throw_error "Project \"${gpp__select_project}\" not found."
            }

            printf "\e[96m%s \e[93m\"%s\"\e[0m\n" \
              "Project: " "${gpp__select_project}" \
              "Repo:    " "${aarr_gpp__psy_projects_repos[${gpp__select_project}]}"

            printf "\n\n"
          done
        }
      }

      { #variables
        unset -v \
          iarr_gpp__psy_projects \
          iarr_gpp__download_projects \
          aarr_gpp__psy_projects_repos

        declare \
          gpp__path_psy_projects_directory="${gpp__path_psy_projects_directory:+}" \
          gpp__select_project="${gpp__select_project:+}" \
          gpp__select_repo="${gpp__select_repo:+}"

        declare -a \
          iarr_gpp__download_projects \
          iarr_gpp__psy_projects

        declare -A aarr_gpp__psy_projects_repos
      }

      { #setting-variables

        { # gpp__path_psy_projects_directory
          gpp__path_psy_projects_directory="$(normalize_path "${directory}")"

          # [[ -d "${path_output_directory}" ]] || mkdir -p "${path_output_directory}"
        }

        { # iarr_gpp__psy_projects
          iarr_gpp__psy_projects=(
            "bash-core-library"
            "psy-bash-tools"
            "psy-dev-utilities"
            "bootstrap-ved"
            "virtual-env-docker"
            "psy-get-binaries"
            "ga-utilities"
          )
        }

        { # aarr_gpp__psy_projects_repos
          aarr_gpp__psy_projects_repos=(
            ["bash-core-library"]="psy-projects-bash/bash-core-library"
            ["psy-bash-tools"]="psy-projects-bash/psy-bash-tools"
            ["psy-dev-utilities"]="psy-projects-bash/psy-dev-utilities"
            ["bootstrap-ved"]="psy-projects-bash/bootstrap-ved"
            ["virtual-env-docker"]="psy-projects-docker/virtual-env-docker"
            ["psy-get-binaries"]="psy-projects-ga/psy-get-binaries"
            ["ga-utilities"]="psy-projects-ga/ga-utilities"
          )
        }

        { # iarr_gpp__download_projects
          if ((all)); then
            iarr_gpp__download_projects=("${iarr_gpp__psy_projects[@]}")
          else
            iarr_gpp__download_projects=("${project}")
          fi
        }
      }

      :

      gpp__run_get_psy_projects
    }
  }

  { #variables
    declare -i \
      all="${all:+0}" \
      git="${git:+0}" \
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
      [[ -n "${directory}" ]] || directory="${HOME}/installations"
      [[ -z "${project}" ]] && printf "\e[91m%s\e[0m\n" "Option \"--project\" is required." && exit 1

      { # root_password
        if [[ -n "${arg_root_password}" ]]; then
          root_password="${arg_root_password}"
        elif [[ -n "${ROOT_PASSWORD:-}" ]]; then
          root_password="${ROOT_PASSWORD}"
        fi
      }

      { # token
        if [[ -n "${arg_git_token}" ]]; then
          token="${arg_git_token}"
        else
          if [[ "${!PSY*}" ]]; then
            : "${!PSY*}" && token="${!_}"
          else
            throw_error "Option \"--token\" is required."
          fi
        fi
      }
    }

    : || { # debug
      printf "\e[92m%s\n" \
        $'\n\n' \
        $'\e[2;92m[DEBUG]\e[0;92m '"${FUNCNAME[0]^}()" \
        $'' \
        "    all:                  \"${all}\"" \
        "    git:                  \"${git}\"" \
        "    list:                 \"${list}\"" \
        "    directory:            \"${directory}\"" \
        "    project:              \"${project}\"" \
        "    root_password:        \"${root_password}\"" \
        "    token:                \"${token}\"" \
        $'\e[0m'
    }
  }

  :

  gpp__get_psy_projects
}

clear
get_psy_projects "${@}"
