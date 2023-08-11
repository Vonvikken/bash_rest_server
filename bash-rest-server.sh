#!/bin/bash

PIPE=bash_server
PORT=29982

HTTP_200="HTTP/1.1 200 OK"
HTTP_404="HTTP/1.0 404"
HTTP_LOCATION="Location:"
HTTP_CONT_LEN="Content-Length:"
HTTP_CONT_TYPE="Content-Type:"
NOT_FOUND_MSG="Resource not found!"

## ~~~ Scripts ~~~

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
        <title>Prova</title>
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

rm -f $PIPE
mkfifo $PIPE
trap "rm -f $PIPE" EXIT

while true; do
    cat $PIPE | nc -lCv -q1 -p $PORT > >(
        while read line; do
            line=$(echo "$line" | tr -d '[\r\n]')

            # echo "***$line***" # DEBUG

            if echo "$line" | grep -qE '^GET /'; then
                REQ=$(echo "$line" | cut -d ' ' -f2)
            elif [ -z "$line" ]; then

                echo "REQUEST -> $REQ" # DEBUG

                CONTENT=
                CONTENT_TYPE=

                case $REQ in
                    /ciao ) 
                        CONTENT_TYPE="text/html"
                        CONTENT=$(handle_ciao) ;;
                    /model/* ) 
                        RESULT=$(handle_model "$REQ")
                        CONTENT_TYPE=$(echo "$RESULT" | head -n 1)
                        CONTENT=$(echo "$RESULT" | tail -n +2)
                        ;;
                esac

                if [ -n "$CONTENT" ]; then
                    CONTENT_LEN=$(calc_content_len "$CONTENT")
                    printf "%s\n%s %d\n%s %s\n\n%s\n" "$HTTP_200" "$HTTP_CONT_LEN" "$CONTENT_LEN" "$HTTP_CONT_TYPE" "$CONTENT_TYPE" "$CONTENT" > $PIPE
                    printf "RESPONSE -> %s\n%s %d\n\n%s\n" "$HTTP_200" "$HTTP_CONT_LEN" "$CONTENT_LEN" "$CONTENT" # DEBUG
                else
                    printf "%s\n\n%s\n" "$HTTP_404" "$NOT_FOUND_MSG" > $PIPE
                    printf "RESPONSE -> %s\n\n%s\n" "$HTTP_404" "$NOT_FOUND_MSG" # DEBUG
                fi
            fi
        done
    )
done

