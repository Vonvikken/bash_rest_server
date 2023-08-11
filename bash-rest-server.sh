#!/bin/bash

PIPE_NAME=bash_server
PORT=29982

HTTP_200="HTTP/1.1 200 OK"
HTTP_404="HTTP/1.1 404 Not Found"
HTTP_LOCATION="Location:"
HTTP_CONT_LEN="Content-Length:"

rm -f $PIPE_NAME
mkfifo $PIPE_NAME
trap "rm -f $PIPE_NAME" EXIT

while true; do
    cat $PIPE_NAME | nc -lCv -p $PORT > >(
        export REQ=
        while read line; do
            line=$(echo "$line" | tr -d '[\r\n]')

            echo "***$line***" # DEBUG

            if echo "$line" | grep -qE '^GET /'; then
                REQ=$(echo "$line" | cut -d ' ' -f2)
            elif [[ -z "$line" ]]; then

                echo "REQUEST -> $REQ" # DEBUG

                CONTENT=$(cat <<'EOF'
<!DOCTYPE html>
<html>
    <head>
        <title>Prova</title>
    </head>
    <body>
        <h2>Ciao!</h2>
        <p style="color: red;">Ciao Mamma!!!</p>
    </body>
</html>
EOF
                )
                CHAR_LEN=$(echo "$CONTENT" | wc -c)
                LINE_LEN=$(echo "$CONTENT" | wc -l)
                CONTENT_LEN=$(($CHAR_LEN+$LINE_LEN)) # Counting lines twice because of double CRLF newlines

                echo "LEN -> $CONTENT_LEN" #DEBUG

                printf "%s\n%s %d\n\n%s\n" "$HTTP_200" "$HTTP_CONT_LEN" "$CONTENT_LEN" "$CONTENT" > $PIPE_NAME

                printf "RESPONSE -> %s\n%s %d\n\n%s\n" "$HTTP_200" "$HTTP_CONT_LEN" "$CONTENT_LEN" "$CONTENT" # DEBUG
            fi
        done
    )
done

