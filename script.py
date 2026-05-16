#!/usr/bin/env python3
"""Genera un archivo .md con nombre aleatorio de 10 chars (letras minúsculas y dígitos)
y dentro escribe un string aleatorio del mismo tipo seguido de ' - ' y la fecha/hora actual.
Luego hace git add ., commit y push.
"""
import secrets
import string
from datetime import datetime
from pathlib import Path
import subprocess
import sys


def random_token(length: int = 10) -> str:
    alphabet = string.ascii_lowercase + string.digits
    return ''.join(secrets.choice(alphabet) for _ in range(length))


def main():
    token = random_token(10)
    filename = f"{token}.md"
    timestamp = datetime.now().strftime("%d/%m/%Y %H:%M")
    content = f"{token} - {timestamp}\n"

    path = Path(filename)
    path.write_text(content, encoding="utf-8")

    try:
        subprocess.run(["git", "add", "."], check=True)
        subprocess.run(["git", "commit", "-m", f"Add {filename}"], check=True)
        subprocess.run(["git", "push"], check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error ejecutando git: {e}", file=sys.stderr)
        sys.exit(1)

    print(f"Creado {filename} y enviado por git.")


if __name__ == "__main__":
    main()
