#!/usr/bin/env bash
# More options for opening URLs through jarun/googler.

url="${1?Please provide a URL.}"
if ! echo "$url" | grep -Eq '^https?://'
then
  url="https://$url"
fi
domain=$(echo "$url" | awk -F[/:] '{print $4}')
case "$domain" in
  reddit.com|www.reddit.com|amp.reddit.com)
    rtv "$url"
    ;;
  *)
    w3m "$url"
    ;;
esac
