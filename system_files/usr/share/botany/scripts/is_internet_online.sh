#!/bin/bash

if [[ $(systemctl is-active network-online.target) == "active" ]]; then
    nslookup -timeout=2 -retry=0 detectportal.firefox.com >/dev/null 2>&1
    if [[ $? == 0 ]]; then
        CURL_DETECTPORTAL_RESPONSE=$(curl http://detectportal.firefox.com/success.txt 2>/dev/null)
        if [[ $? == 0 && "$CURL_DETECTPORTAL_RESPONSE" == "success" ]]; then
            exit 0
        fi
    fi
fi

exit 1
