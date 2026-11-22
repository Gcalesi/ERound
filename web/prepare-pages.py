"""Prepare a Godot Web export for static hosting on GitHub Pages."""

import argparse
import gzip
import shutil
from pathlib import Path

GODOT_FETCH = "return fetch(file).then(function (response) {"
PAGES_FETCH = """const url = new URL(file, document.baseURI);
		const isWasm = url.pathname.endsWith(".wasm");
		if (isWasm) {
			url.pathname += ".gz";
		}
		return fetch(url).then(async (response) => {
			if (!isWasm || !response.ok) {
				return response;
			}
			const stream = response.body.pipeThrough(new DecompressionStream("gzip"));
			return new Response(stream, {headers: {"Content-Type": "application/wasm"}});
		}).then(function (response) {"""


def prepare(export: Path) -> None:
    engine = export / "index.js"
    source = engine.read_text(encoding="utf-8")
    if source.count(GODOT_FETCH) != 1:
        raise ValueError("Expected an unmodified Godot 4.7.2 Web export named index.html.")

    wasm = export / "index.wasm"
    with wasm.open("rb") as original, (export / "index.wasm.gz").open("wb") as compressed:
        with gzip.GzipFile(fileobj=compressed, mode="wb", filename="", mtime=0) as target:
            shutil.copyfileobj(original, target)

    engine.write_text(source.replace(GODOT_FETCH, PAGES_FETCH), encoding="utf-8")
    page = export / "index.html"
    html = page.read_text(encoding="utf-8")
    html = html.replace('lang="en"', 'lang="pt-BR"')
    html = html.replace(
        "Your browser does not support JavaScript.",
        "Ative o JavaScript no navegador para jogar ERounds.",
    )
    html = html.replace(
        "The following features required to run Godot projects on the Web are missing:",
        "Este navegador não oferece todos os recursos necessários para rodar o jogo:",
    )
    page.write_text(html, encoding="utf-8")
    (export / ".nojekyll").touch()
    wasm.unlink()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("export", type=Path, help="Folder containing index.html and its Godot assets")
    prepare(parser.parse_args().export)
