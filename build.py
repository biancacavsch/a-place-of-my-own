#!/usr/bin/env python3
"""
build.py - Gera data/posts.json a partir de data/posts/*.md

Lê cada arquivo Markdown com frontmatter YAML, converte o corpo
para HTML, e gera o posts.json que o blog.js consome.

Uso:
    python3 build.py

Dependência:
    pip install markdown
"""

import json
import os
import glob
import markdown

POSTS_DIR = os.path.join(os.path.dirname(__file__), "data", "posts")
OUTPUT = os.path.join(os.path.dirname(__file__), "data", "posts.json")


def parse_frontmatter(text):
    """Extrai frontmatter YAML do início do arquivo Markdown."""
    if not text.startswith("---"):
        return {}, text

    parts = text.split("---", 2)
    if len(parts) < 3:
        return {}, text

    raw_yaml = parts[1].strip()
    body = parts[2].strip()

    # Parser YAML simples (sem dependência externa)
    meta = {}
    current_key = None
    current_list = None

    for line in raw_yaml.split("\n"):
        line = line.rstrip()

        # Lista indentada (começa com -)
        if line.startswith("  - ") and current_key:
            if current_list is None:
                current_list = []
            current_list.append(line.strip("- ").strip())
            meta[current_key] = current_list
            continue

        # Nova chave: valor
        if ": " in line or line.endswith(":"):
            # Salva lista anterior
            if current_list is not None:
                meta[current_key] = current_list
                current_list = None

            key, _, value = line.partition(":")
            key = key.strip()
            value = value.strip()

            if value == "":
                # Lista ou dict vazio - espera próximo item
                current_key = key
                current_list = None
                continue

            # Remove aspas
            if (value.startswith('"') and value.endswith('"')) or \
               (value.startswith("'") and value.endswith("'")):
                value = value[1:-1]

            # Lista inline: [a, b, c]
            if value.startswith("[") and value.endswith("]"):
                items = [i.strip().strip('"').strip("'")
                         for i in value[1:-1].split(",")]
                meta[key] = items
            else:
                meta[key] = value
                current_key = key
                current_list = None

    # Salva última lista se houver
    if current_list is not None and current_key:
        meta[current_key] = current_list

    return meta, body


def build():
    """Lê todos os .md, gera posts.json."""
    pattern = os.path.join(POSTS_DIR, "*.md")
    files = sorted(glob.glob(pattern))

    if not files:
        print(f"Nenhum arquivo .md encontrado em {POSTS_DIR}")
        return

    posts = []
    for filepath in files:
        with open(filepath, "r", encoding="utf-8") as f:
            text = f.read()

        meta, body = parse_frontmatter(text)

        # Converte Markdown para HTML
        html = markdown.markdown(body, extensions=["extra", "smarty"])

        post = {
            "titulo": meta.get("titulo", os.path.basename(filepath)),
            "data": meta.get("data", ""),
            "tags": meta.get("tags", []),
            "capa": meta.get("capa", "📖"),
            "autor": meta.get("autor", ""),
            "nota": meta.get("nota", ""),
            "corpo": html,
        }
        posts.append(post)

    # Ordena por data (mais recente primeiro)
    posts.sort(key=lambda p: p["data"], reverse=True)

    # Salva JSON
    os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)
    with open(OUTPUT, "w", encoding="utf-8") as f:
        json.dump(posts, f, ensure_ascii=False, indent=2)

    print(f"✓ {len(posts)} post(s) gerado(s) → {OUTPUT}")


if __name__ == "__main__":
    build()
