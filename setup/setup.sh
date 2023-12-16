#!/bin/env bash

FILEPATH=/usr/local/bin/setup
. "$FILEPATH"/excuteMap
. "$FILEPATH"/controllOutput
. "$FILEPATH"/gitsetup.conf

# オプション整形: オプション部/引数部を分類
function format_OptArg() {
    OPTION_ARG=()
    INSTALL_ARG=()
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -* ) OPTION_ARG+=("$1") ; shift ;;
            *  ) INSTALL_ARG+=("$1"); shift ;;
        esac
    done
}

# オプション混合のエラーとオプションなしの挙動
function error_option() {
    case "$2" in
    --*) if [[ "$*" = *[^-]-[A-Za-z]* ]];   then warn 0101 ; fi ;;
    -* ) if [[ "$*" = *--* ]];              then warn 0101 ; fi ;;
    *  )
        if [[ "$1" = noArg ]]; then
            if [[ -n "${INSTALL_ARG[*]}" ]]; then warn 1202
            else OPTION_ARG=("-a") ; INSTALL_ARG=("VSCode" "Chrome")
            fi
        fi
        if [[ "$1" = AP    ]] && [[ -z "${INSTALL_ARG[*]}" ]]; then OPTION_ARG=("-a"); fi
        if [[ "$1" = FTM   ]] && [[ -z "${INSTALL_ARG[*]}" ]]; then OPTION_ARG=("-o"); fi
        ;;
    esac
}

# コマンド引数なしのときの動作
function arg_no() {
    format_OptArg "$@"
    set -- "${OPTION_ARG[@]}"; unset OPTION_ARG

    #ロング/ショートオプションの混合に関するエラー処理/オプションなしのときの
    error_option noArg "$@"

    # ショートオプションの統一（-. に変換）
    if [[ ! "$*" = --* ]]; then
        while [[ "$#" -gt 0 ]]; do
            case "$1" in
                -[a-z]  ) OPTION_ARG+=("$1"); shift ;;  # 単体ショートオプション
                -[a-z]?*) OPTIONS="$1"                  # 結合ショートオプション
                    for (( i=1; i<${#OPTIONS}; i++ )); do
                        OPTION_ARG+=("-${OPTIONS:$i:1}")
                    done; shift ;;
            esac
        done
        unset OPTIONS
        set -- "${OPTION_ARG[@]}"; unset OPTION_ARG;
    fi
    OPTION_ARG=()
    # オプションをショートオプションに変換
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
        -a|--all                   ) OPTION_ARG+=("-a"); shift ;;
        -b|--build-Language-env    ) OPTION_ARG+=("-b"); shift ;;
        -c|--clean                 ) OPTION_ARG+=("-c"); shift ;;
        -d|--delete-app            ) OPTION_ARG+=("-d"); shift ;;
        -g|--setting-git           ) OPTION_ARG+=("-g"); shift ;;
        -h|--help                  ) OPTION_ARG+=("-h"); shift ;;
        -i|--install-app           ) OPTION_ARG+=("-i"); shift ;;
        -j|--Japanese-localization ) OPTION_ARG+=("-j"); shift ;;
        -m|--min                   ) OPTION_ARG+=("-m"); shift ;;
        -p|--install-package       ) OPTION_ARG+=("-p"); shift ;;
        -s|--setting-research      ) OPTION_ARG+=("-s"); shift ;;
        -u|--update                ) OPTION_ARG+=("-u"); shift ;;
        -v|--version               ) OPTION_ARG+=("-v"); shift ;;
        -*                         ) warn 1101 "$1"            ;;
        esac
    done
    set -- "${OPTION_ARG[@]}"; unset OPTION_ARG;

    OPT_FLAG=0
    REBOOT=n
    # 優先度決定
    if [[ "$*" = *-h* ]]; then usage noArg; set -- ; fi
    if [[ "$*" = *-a* ]] && [[ "$#" -gt 1 ]]; then warn 1102; fi
    if [[ "$*" = *-v* ]]; then showVersion;  fi
    while [[ "$#" -gt 0 ]]; do
        case "$1" in           #option:  cisgdbjpu
        -a ) OPT_FLAG=$(("$OPT_FLAG" | 2#111111111)); shift ;;
        -b ) OPT_FLAG=$(("$OPT_FLAG" | 2#100001001)); shift ;;
        -c ) OPT_FLAG=$(("$OPT_FLAG" | 2#100000000)); shift ;;
        -d ) OPT_FLAG=$(("$OPT_FLAG" | 2#100010000)); shift ;;
        -g ) OPT_FLAG=$(("$OPT_FLAG" | 2#000100000)); shift ;;
        -i ) OPT_FLAG=$(("$OPT_FLAG" | 2#110000001)); shift ;;
        -j ) OPT_FLAG=$(("$OPT_FLAG" | 2#100000101)); shift REBOOT=y;;
        -m ) OPT_FLAG=$(("$OPT_FLAG" | 2#100000111)); shift ;;
        -p ) OPT_FLAG=$(("$OPT_FLAG" | 2#100000011)); shift ;;
        -s ) OPT_FLAG=$(("$OPT_FLAG" | 2#001000000)); shift ;;
        -u ) OPT_FLAG=$(("$OPT_FLAG" | 2#100000001)); shift ;;
        -v )                                          shift ;;
        esac
    done

    #実行部分
    DISTINC_ARG=2#000000001
    for (( i=0; i<9; i++ )); do
        case "$(( OPT_FLAG & DISTINC_ARG ))" in
            $((2#000000001)) ) update                                 ;; # -u
            $((2#000000010)) ) install_package                        ;; # -p
            $((2#000000100)) ) japanalize                             ;; # -j
            $((2#000001000)) ) build_developenv                       ;; # -b
            $((2#000010000)) ) deleateApplication                     ;; # -d
            $((2#000100000)) ) setup_git                              ;; # -g
            $((2#001000000)) ) StudySetup                             ;; # -s
            $((2#010000000)) ) installApplication "${INSTALL_ARG[@]}" ;; # -i
            $((2#100000000)) ) clean                                  ;; # -c
        esac
        DISTINC_ARG="$(( DISTINC_ARG << 1))"
    done
    set -- "$REBOOT"
    unset OPT_FLAG DISTINC_ARG INSTALL_ARG REBOOT
    if [[ "$1" = y ]]; then  reboot; fi
}


#####################################################################
# 変数宣言


# コマンド引数による分岐
if [[ "$*" = -h  ]] || [[ "$*" = --help ]]; then usage help
else
    arg_no  "$@"
fi
unset FILEPATH
