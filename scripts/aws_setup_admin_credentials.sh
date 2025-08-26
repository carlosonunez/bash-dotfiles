#!/usr/bin/env bash
source "$(dirname "$0")/../.bash_onepassword_specific"
DEFAULT_ROLE_NAME=admin-access-role
DEFAULT_USER_NAME=superuser
OP_CACHE=""

usage() {
  cat <<-USAGE
$(basename "$0") --onepass-login-name [NAME]
Creates admin credentials in an AWS account.

OPTIONS

  --onepass-login-name [NAME]   (required) The 1Password login name containing "root"
                                AWS credentials for this script.
  --onepass-vault [NAME]        The 1Password vault to use for --onepass-login-name
                                (default: $OP_DEFAULT_VAULT)
  --role-name [NAME]            The name to give the admin role.
                                (default: $DEFAULT_ROLE_NAME)
  --user-name [NAME]            The name to give the user that will assume this role.
                                (default: $DEFAULT_USER_NAME)
  -h, --help                    Prints this help message.

NOTES

- All options can be defined with environment variables by capitalizing the option name
  and replacing hyphens for spaces.

  Example: The environment variable for --role-name is ROLE_NAME.
USAGE
}

_get_value() {
  local k default_value
  k="${1//--/}"
  # shellcheck disable=SC2001
  env_k="$(sed 's/-/_/g' <<< "${k^^}")"
  shift
  default_value="$1"
  shift
  while test "$#" -gt 0
  do
    if test -n "${!env_k}"
    then
      echo "${!env_k}"
      return 0
    fi
    if test "--$k" == "$1"
    then
      echo "$2"
      return 0
    fi
    shift
  done
  if test -n "$default_value"
  then
    echo "$default_value"
    return 0
  fi
  return 1
}

_read_op_cache() {
  local k
  k="$1"
  grep -E "^$k" <<< "$OP_CACHE" | sed -E 's/.*%%%VAL%%%//'
}

_write_op_cache() {
  local k v
  k="$1"
  v="$2"
  OP_CACHE="$(sed -E "/^$k/d" <<< "$OP_CACHE")"
  OP_CACHE="$(printf "%s\n%s%s%s" "$OP_CACHE" "$k" "%%%VAL%%%" "$v")"
}

_get_from_login_item() {
  local json
  json="$1"
  if test -n "$(_read_op_cache "$2")"
  then
    echo "$(_read_op_cache "$2")"
    return 0
  fi
  val=$(jq -r '.fields[] | select(.label == "'"$2"'") | .value' <<< "$json")
  test "$?" -ne 0 && return "$?"
  _write_op_cache "$2" "$val"
  echo "$val"
}

_root_aws_access_key_from_login_item() {
  _get_from_login_item "$1" 'root_access_key'
}

_root_aws_secret_key_from_login_item() {
  _get_from_login_item "$1" 'root_secret_access_key'
}

help_requested() {
  grep -Eiq '^(-h|--help)$' <<< "$@"
}

get_value() {
  _get_value "$1" "" "$@"
}

get_value_with_default() {
  _get_value "$1" "$2" "$@"
}

get_onepass_login_item() {
  local name vault result
  name="$1"
  vault="$2"
  result=$(get_item_json "$name" "$vault")
  test -z "$result" && return 1
  echo "$result"
}

_aws_admin_user_exists() {
  test -n "$(aws iam list-users |
    jq --arg name "$1" -r '.Users[] | select(.UserName == $name) | .Arn')"
}

_aws_get_user_arn_from_name() {
  aws iam get-user --user-name "$1" | jq -r '.User.Arn'
}

_aws_get_role_arn_from_name() {
  aws iam get-role --role-name "$1" | jq -r '.Role.Arn'
}

_aws_admin_role_exists() {
  local role_name
  role_name="$1"
  role=$(aws iam list-roles |
    jq --arg name "$role_name" -r '.Roles[] | select(.RoleName == $name) | .')
  test -n "$role"
}

_aws_ensure_assume_role_principal_is_an_arn() {
  local hits role_name user_arn
  role_name="$1"
  user_arn="$2"
  hits=1
  while true
  do
    test "$hits" == 10 && return 0
    got_arn=$(aws iam get-role --role-name "$role_name" |
      jq -r '.Role.AssumeRolePolicyDocument.Statement[0].Principal.AWS')
    test "$got_arn" == "$user_arn" || break
    hits=$((hits+1))
    sleep 0.5
  done
  return 1
}

_aws_clear_user_access_keys_if_any() {
  ak=$(2>/dev/null aws iam list-access-keys --user-name "$1" |
    jq -r '.AccessKeyMetadata[0].AccessKeyId' | { grep -v 'null' || true; } )
  test -z "$ak" && return 0
  aws iam delete-access-key --user-name "$1" --access-key-id "$ak"
}

aws_credentials_missing_from_onepassword_login_item() {
  missing=""
  for part in access secret
  do
    k="root_aws_${part}_key"
    test -n "$(eval "_${k}_from_login_item '$1'")" && continue
     missing="${missing}${k} "
  done
  test -z "$missing" && return 0
  sed -E 's/ $//' <<< "$missing"
  return 1
} 

aws_create_admin_user() {
  if _aws_admin_user_exists "$1"
  then
    _aws_clear_user_access_keys_if_any "$1" || return 1
    aws iam delete-user --user-name "$1"
  fi
  aws iam create-user --user-name "$1" >/dev/null
}

aws_create_access_key_for_admin_user() {
  local ak sk creds
  _aws_clear_user_access_keys_if_any "$1" || return 1
  creds=$(aws iam create-access-key --user-name "$1")
  ak="$(jq -r '.AccessKey.AccessKeyId' <<< "$creds")"
  sk="$(jq -r '.AccessKey.SecretAccessKey' <<< "$creds")"
  printf '{"access_key_id":"%s","secret_access_key":"%s"}' "$ak" "$sk"
}

aws_create_admin_role() {
  local role_name user_name user_arn assume_role_policy external_id
  role_name="$1"
  user_name="$2"
  external_id="$3"
  user_arn="$(_aws_get_user_arn_from_name "$user_name")"
  attempts=1
  while test "$attempts" -le 10
  do
    test "$attempts" -gt 1 &&
      >&2 echo "WARNING: role '$role_name' is using a stale user ID; trying again ($attempts/10)"
    if _aws_admin_role_exists "$role_name"
    then
      policy_arn=$(aws iam list-attached-role-policies --role-name "$role_name" |
        jq -r '.AttachedPolicies[] | select(.PolicyArn | contains("AdministratorAccess")) | .PolicyArn') || return 1
      test -n "$policy_arn" && aws iam detach-role-policy --role-name "$role_name" --policy-arn "$policy_arn"
      aws iam delete-role --role-name "$role_name"
    fi
    assume_role_policy=$(cat <<-JSON
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Principal": {
              "AWS": "$user_arn"
          },
          "Action": "sts:AssumeRole",
          "Condition": {
              "StringEquals": {
                  "sts:ExternalId": "$external_id"
              }
          }
      }
  ]
}
JSON
  )
    aws iam create-role --role-name "$role_name" \
      --assume-role-policy "$assume_role_policy" \
      --tags "Key=admin_role,Value=true" >/dev/null
    # There seems to be an eventual consistency issue that happens where a user
    # ARN in a assume role policy evaluates to a previous user. I think this
    # only happens when a user is deleted and recreated quickly, which happened
    # while this script was being tested.
    _aws_ensure_assume_role_principal_is_an_arn "$role_name" "$user_arn" && return 0
    attempts=$((attempts+1))
  done
  return 1
}

aws_attach_admin_access_policy_to_role() {
  aws iam attach-role-policy --policy-arn 'arn:aws:iam::aws:policy/AdministratorAccess' \
    --role-name "$1"
}

aws_print_creds() {
  local role_arn
  role_arn=$(_aws_get_role_arn_from_name "$1")
  printf '{"role_arn": "%s", "credentials": %s}' "$role_arn" "$2" | jq .
}

aws_credential_exports_from_onepassword_login_item() {
  cat <<-EXPORTS
export AWS_ACCESS_KEY_ID=$(_root_aws_access_key_from_login_item "$1")
export AWS_SECRET_ACCESS_KEY=$(_root_aws_secret_key_from_login_item "$1")
export AWS_SESSION_TOKEN=''
EXPORTS
}

update_onepassword_login_item_creds() {
  local item role_name creds external_id
  item="$1"
  role_name="$2"
  creds="$3"
  external_id="$4"
  role_arn=$(_aws_get_role_arn_from_name "$role_name")
  ak=$(jq -r '.access_key_id' <<< "$creds")
  sk=$(jq -r '.secret_access_key' <<< "$creds")
  op_edit_item "$item" "arn=$role_arn" \
    "access_key=$ak" \
    "secret_key[password]=$sk" \
    "external_id[password]=$external_id"
}

generate_external_id() {
  local attempts
  attempts=1
  while test "$attempts" -lt 10
  do
    val=$(tr -dc 'a-zA-Z0-9-=,.@:' < /dev/urandom | head -c 32)
    if grep -Eq '^[A-Za-z]' <<< "$val"
    then
      echo "$val"
      return 0
    fi
  done
}

set -eo pipefail

if help_requested "$@"
then
  usage
  exit 0
fi
if ! login_item=$(get_value "onepass-login-name" "$@")
then
  usage
  >&2 echo "ERROR: --onepass-login-name must be set."
  exit 1
fi
if ! vault=$(get_value_with_default "onepass-vault-name" "$OP_DEFAULT_VAULT")
then
  usage
  >&2 echo "ERROR: OP_DEFAULT_VAULT not set."
  exit 1
fi
external_id=$(generate_external_id)
role_name=$(get_value_with_default "role-name" "$DEFAULT_ROLE_NAME" "$@")
user_name=$(get_value_with_default "user-name" "$DEFAULT_USER_NAME" "$@")
if ! login_details=$(get_onepass_login_item "$login_item" "$vault")
then
  >&2 echo "ERROR: Failed to get details for 1Password login item '$login_item'"
  exit 1
fi
if ! missing=$(aws_credentials_missing_from_onepassword_login_item "$login_details")
then
  usage
  >&2 echo "ERROR: Please ensure these fields are defined in [$login_item]: $missing"
  exit 1
fi
eval $(aws_credential_exports_from_onepassword_login_item "$login_details")
aws_create_admin_user "$user_name"
creds_json=$(aws_create_access_key_for_admin_user "$user_name")
aws_create_admin_role "$role_name" "$user_name" "$external_id"
aws_attach_admin_access_policy_to_role "$role_name"
update_onepassword_login_item_creds "$login_item" "$role_name" "$creds_json" "$external_id"
