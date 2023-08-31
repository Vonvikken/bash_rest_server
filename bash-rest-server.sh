#!/bin/bash

PIPE=bash_server
PORT=20000

HTTP_200="HTTP/1.1 200 OK"
HTTP_404="HTTP/1.0 404"
HTTP_LOCATION="Location:"
HTTP_CONT_LEN="Content-Length:"
HTTP_CONT_TYPE="Content-Type:"
NOT_FOUND_MSG="Resource not found!"

## ~~~ Handler scripts ~~~

HANDLE_MODEL_PATH="./handle_model.sh"

## ~~~ Functions ~~~

function calc_content_len
{
    CHAR_LEN=$(echo "$1" | wc -c)
    LINE_LEN=$(echo "$1" | wc -l)
    echo -n $(($CHAR_LEN+$LINE_LEN)) # Counting lines twice because of double CRLF newlines
}

function handle_ciao
{
    cat <<'EOF'
<!DOCTYPE html>
<html>
    <head>
        <title>Sample</title>
    </head>
    <body>
        <h2>Ciao!</h2>
        <p style="color: red;">Ciao!!!</p>
    </body>
</html>
EOF
}

function handle_model
{
    echo -n "$($HANDLE_MODEL_PATH $1)"
}

## ~~~ Main ~~~

# Remove existing pipe before recreating it
rm -f $PIPE
mkfifo $PIPE

# Ensuring that the pipe is removed when the script exits
trap "rm -f $PIPE" EXIT

while true; do
    cat $PIPE | nc -lC -q1 -p $PORT > >(
        while read line; do
            line=$(echo "$line" | tr -d '[\r\n]')

            if echo "$line" | grep -qE '^GET /'; then
                # Look for a GET request, then extract it
                REQ=$(echo "$line" | cut -d ' ' -f2)
            elif [ -z "$line" ]; then
                # When encountering an empty line, let's suppose that we reached the end of the HTTP header, so we can proceed

                CONTENT=
                CONTENT_TYPE=

                case $REQ in
                    /ciao )
                        # Sample request
                        CONTENT_TYPE="text/html"
                        CONTENT=$(handle_ciao) ;;
                    /model/* )
                        # Simple scale model inventory management
                        # Process the request, then extract the content type and the content
                        RESULT=$(handle_model "$REQ")
                        CONTENT_TYPE=$(echo "$RESULT" | head -n 1)
                        CONTENT=$(echo "$RESULT" | tail -n +2)
                        ;;
                    # Additional paths here
                esac

                if [ -n "$CONTENT" ]; then
                    # If there is a content to display, respond with HTTP 200 and the content
                    CONTENT_LEN=$(calc_content_len "$CONTENT")
                    printf "%s\n%s %d\n%s %s\n\n%s\n" "$HTTP_200" "$HTTP_CONT_LEN" "$CONTENT_LEN" "$HTTP_CONT_TYPE" "$CONTENT_TYPE" "$CONTENT" > $PIPE
                else
                    # Otherwise respond with HTTP 404
                    printf "%s\n\n%s\n" "$HTTP_404" "$NOT_FOUND_MSG" > $PIPE
                fi
            fi
        done
    )
done

