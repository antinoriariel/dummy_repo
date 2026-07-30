#!/bin/sh
# Genera una cantidad aleatoria (5-100) de commits locales con fechas
# aleatorias dentro de un rango dado. No hace push, solo crea commits
# locales en el repositorio actual.
#
# Uso:
#   ./generate_commits.sh FECHA_INICIO FECHA_FIN [CANTIDAD]
#
#   FECHA_INICIO / FECHA_FIN : formato YYYY-MM-DD
#   CANTIDAD                 : opcional, entero entre 5 y 100.
#                               Si se omite, se elige al azar en ese rango.
#
# Ejemplos:
#   ./generate_commits.sh 2026-01-01 2026-01-31
#   ./generate_commits.sh 2026-01-01 2026-01-31 40

set -e

usage() {
    echo "Uso: $0 FECHA_INICIO FECHA_FIN [CANTIDAD]" >&2
    echo "  FECHA_INICIO / FECHA_FIN : formato YYYY-MM-DD" >&2
    echo "  CANTIDAD                 : entero entre 5 y 100 (opcional, aleatorio si se omite)" >&2
    exit 1
}

[ $# -lt 2 ] && usage

START_DATE=$1
END_DATE=$2
COUNT=$3

# Entero aleatorio en [0, max)
rand_int() {
    max=$1
    n=$(od -An -N2 -tu2 /dev/urandom | tr -d ' ')
    echo $((n % max))
}

# Nombre aleatorio de 10 caracteres alfanumericos en minuscula
rand_name() {
    tr -dc 'a-z0-9' < /dev/urandom | head -c 10
}

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "Error: este directorio no es un repositorio git" >&2
    exit 1
}

START_EPOCH=$(date -d "$START_DATE" +%s 2>/dev/null) || {
    echo "Error: fecha de inicio invalida: $START_DATE" >&2
    exit 1
}
END_EPOCH=$(date -d "$END_DATE" +%s 2>/dev/null) || {
    echo "Error: fecha de fin invalida: $END_DATE" >&2
    exit 1
}

if [ "$END_EPOCH" -lt "$START_EPOCH" ]; then
    echo "Error: la fecha de fin debe ser posterior o igual a la fecha de inicio" >&2
    exit 1
fi

DAY_SPAN=$(( (END_EPOCH - START_EPOCH) / 86400 + 1 ))

if [ -z "$COUNT" ]; then
    COUNT=$(( $(rand_int 96) + 5 ))
else
    case "$COUNT" in
        ''|*[!0-9]*)
            echo "Error: CANTIDAD debe ser un numero entero" >&2
            exit 1
            ;;
    esac
    if [ "$COUNT" -lt 5 ] || [ "$COUNT" -gt 100 ]; then
        echo "Error: CANTIDAD debe estar entre 5 y 100" >&2
        exit 1
    fi
fi

echo "Generando $COUNT commits entre $START_DATE y $END_DATE (sin push)..."

TMPFILE=$(mktemp)

i=0
while [ "$i" -lt "$COUNT" ]; do
    DAY_OFFSET=$(rand_int "$DAY_SPAN")
    SEC_OFFSET=$(rand_int 86400)
    TS=$((START_EPOCH + DAY_OFFSET * 86400 + SEC_OFFSET))
    echo "$TS" >> "$TMPFILE"
    i=$((i + 1))
done

sort -n "$TMPFILE" -o "$TMPFILE"

while IFS= read -r TS; do
    ISO=$(date -d "@$TS" +"%Y-%m-%dT%H:%M:%S")
    DD=$(date -d "@$TS" +"%d")
    MM=$(date -d "@$TS" +"%m")
    YYYY=$(date -d "@$TS" +"%Y")
    HH=$(date -d "@$TS" +"%H")
    MI=$(date -d "@$TS" +"%M")

    FNAME=""
    while [ -z "$FNAME" ]; do
        CANDIDATE=$(rand_name)
        [ -f "${CANDIDATE}.md" ] || FNAME=$CANDIDATE
    done

    printf "%s - %s/%s/%s %s:%s\n" "$FNAME" "$DD" "$MM" "$YYYY" "$HH" "$MI" > "${FNAME}.md"
    git add "${FNAME}.md"
    GIT_AUTHOR_DATE="$ISO" GIT_COMMITTER_DATE="$ISO" git commit -q -m "Add ${FNAME}.md"
    echo "Commit creado: ${FNAME}.md -> $ISO"
done < "$TMPFILE"

rm -f "$TMPFILE"

echo "Listo. $COUNT commits generados localmente (recuerda: no se hizo push)."
