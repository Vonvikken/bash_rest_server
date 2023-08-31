#!/bin/bash

# Storage file format: POSITION|NAME|BRAND
IN_FILE="models.txt"

## ~~~ Functions ~~~

function to_json
{
    if [ -n "$1" ]; then
        JSON=$(echo "$1" \
            | awk -F'|' '{print "{\"box\":\"" $1 "\",\"name\":\"" $2 "\",\"brand\":\"" $3 "\"}" }' \
            | paste -d, -s \
            )
        echo "[$JSON]"
    else
        echo ""
    fi
}

function to_html
{
    if [ -n "$1" ]; then
        HTML=$(echo "$1" \
            | sed 's/\\"/"/g' \
            | awk -F'|' '{print "                <tr><td>" $1 "</td><td>" $2 "</td><td>" $3 "</td></tr>" }' \
            | paste -d '\n' -s \
            )

        cat << EOF
<!DOCTYPE html>
<html>
    <head>
        <style>
            table { width: 100%; }
            table, th, td { border: 1px solid black; }
            th { background-color: #eee; }
        </style>
    </head>
    <body>
        <table>
            <thead>
                <tr>
                    <th>Box</th>
                    <th>Name</th>
                    <th>Brand</th>
                </tr>
            </thead>
            <tbody>
$HTML
            </tbody>
        </table>
    </body>
</html>
EOF
    else
        echo ""
    fi
}

## ~~~ Main ~~~

# Request: /model/QUERY/PARAM          -> JSON output
#          /model/QUERY/PARAM?fmt=json -> JSON output
#          /model/QUERY/PARAM?fmt=html -> HTML output
QUERY=$(echo "$1" | cut -d '/' -f3)
PARAM=$(echo "$1" | cut -d '/' -f4)

if [ $(echo "$PARAM" | grep -c '?') -eq '0' ]; then
    # Default case (no 'fmt' option)
    OUT_FMT="json"
else
    OUT_FMT=$(echo "$PARAM" | cut -d '?' -f2 | cut -d '=' -f2)
    PARAM=$(echo "$PARAM" | cut -d '?' -f1)
fi

QUERY_REGEX=

case $QUERY in
    box )
        QUERY_REGEX="^box_$PARAM" ;;
    brand )
        QUERY_REGEX="\|$PARAM\s*" ;;
    # Other queries here
esac

if [ -z "$QUERY_REGEX" ]; then
    OUTPUT=
else
    CONTENT=$(cat "$IN_FILE" \
        | sed '/^#.*/d' \
        | sed 's/^$//g' \
        | sed 's/"/\\\"/g' \
        | grep -Ei $(echo "$QUERY_REGEX") \
        | sort -k2 -t'|' -d \
        )

    case $OUT_FMT in
        json )
            CONTENT_TYPE="application/json"
            OUTPUT=$(to_json "$CONTENT") ;;
        html )
            CONTENT_TYPE="text/html"
            OUTPUT=$(to_html "$CONTENT") ;;
        # Other formats here
    esac
fi

# Echo the content type in the first line, the actual content in the following ones
echo "$CONTENT_TYPE"
echo "$OUTPUT"

