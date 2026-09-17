#!/usr/bin/env bash
source "$HOME/src/setup/.bash_functions"
source "$HOME/src/setup/.bash_onepassword_specific"
source "$HOME/src/setup/.bash_secret_exports"
LOG_FILE="${OP_CONFIG_DIR}/pinentry.log"

_keygrip_cached() {
  gpg-connect-agent 'keyinfo --list' /bye |
    grep "KEYINFO $1" |
    grep -q "1 P"
}

_get_password_from_1password() {
  set -x
  local email fpr
  email=''
  fpr=''
  pw=notsetyet
  echo "OK"
  # shellcheck disable=SC2162
  while read key value
  do
    >&2 echo "key: $key, value(s): $value"
    case "${key^^}" in
      SETDESC*)
        # You're asked twice to confirm deletion before pinentry gets to it; move on
        if grep -q "permanently delete" <<< "$value"
        then
          echo "OK"
        else
          email=$(sed -E 's/.*<(.*)>.*/\1/g' <<< "$value" |
            tr -d '<>' |
            sed 's/%2B/+/g')
          if test -z "$email"
          then echo "ERR 118"
          else
            fpr="$(gpg --list-keys --with-keygrip --with-colons "$email" |
              grep fpr |
              cut -f10 -d ':' |
              tr '\n' ',' |
              sed -E 's/,$//')"
            >&2 echo "debug: email: $email, fpr(s): $fpr"
            if test -z "$fpr"
            then
              >&2 echo "ERROR: Couldn't obtain fingerprint for email '$email'"
              echo "ERR 239"
            else echo "OK"
            fi
          fi
        fi
        ;;
      BYE*)
        echo "OK"
        exit 0
        ;;
      GETPIN)
        if ! _1pass_token_valid
        then
          # shellcheck disable=SC2016
          >&2 echo '1Password token not valid; run `eval "$(op_configure_cli)"` to fix'
          echo 'ERR 153'
        else
          >&2 echo "sending request to op_cli now"
          pw="$(2>>"$LOG_FILE" op_cli item get "GPG Key: $email" --fields=password --reveal)"
          if test -z "$pw"
          then
            >&2 echo "op_cli call failed"
            echo "ERR 178"
          else echo "D $pw"
          fi
          echo "OK"
        fi
        ;;
      *)
        echo "OK"
        ;;
    esac
  done
}

print() {
  >&2 echo "pinentry: $OP_DISABLE_PINENTRY"
}

rm "$LOG_FILE"
if test -n "$OP_DISABLE_PINENTRY"
then
  2>>"$LOG_FILE" print
  $(which pinentry-tty) "$@"
else
  echo "1password pinentry started, options: $*" >>"$HOME/.config/op/pinentry.log"
  2>>"$LOG_FILE" _get_password_from_1password "$@"
fi
