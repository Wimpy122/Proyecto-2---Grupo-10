# Claudio González - Gabriel Garcia - Moisés Pacheco

"""Corre las 20 preguntas en ambas versiones y genera resultados.json / resultados.md.

    python evaluacion/evaluar.py            
    python evaluacion/evaluar.py --solo-prolog

El 'acierto automatico' solo busca palabras clave esperadas.
"""
import json
import os
import sys
import time
import unicodedata
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RAIZ))
from bots.llm_bot import LLMBot            # noqa: E402
from bots.prolog_bridge import PrologBot   # noqa: E402


def norm(t):
    t = unicodedata.normalize("NFD", t.lower())
    return "".join(c for c in t if unicodedata.category(c) != "Mn")


def acierta(resp, p):
    r = norm(resp)
    todos = all(norm(x) in r for x in p.get("esperado_todos", []))
    alguno = True
    if p.get("esperado_alguno"):
        alguno = any(norm(x) in r for x in p["esperado_alguno"])
    return todos and alguno


def main():
    solo_prolog = "--solo-prolog" in sys.argv
    preguntas = json.loads((RAIZ / "evaluacion" / "preguntas.json").read_text(encoding="utf-8"))
    prolog = PrologBot()                      # estado inicial limpio
    usar_llm = not solo_prolog and bool(os.environ.get("GEMINI_API_KEY"))
    llm = LLMBot(prolog) if usar_llm else None
    if not usar_llm and not solo_prolog:
        print("AVISO: no hay GEMINI_API_KEY; se evalua solo Prolog.")

    filas = []
    for p in preguntas:
        fila = dict(p)
        t0 = time.perf_counter()
        fila["prolog"] = prolog.preguntar(p["pregunta"])
        fila["prolog_ms"] = round((time.perf_counter() - t0) * 1000, 1)
        fila["prolog_ok"] = acierta(fila["prolog"], p)
        if llm:
            t0 = time.perf_counter()
            try:
                fila["llm"] = llm.preguntar(p["pregunta"])
            except Exception as e:
                fila["llm"] = f"[ERROR] {e}"
            fila["llm_ms"] = round((time.perf_counter() - t0) * 1000, 1)
            fila["llm_ok"] = acierta(fila["llm"], p)
            time.sleep(4)  # evita el limite de peticiones por minuto del plan gratuito
        filas.append(fila)
        print(f"{p['id']:>2} prolog={'OK ' if fila['prolog_ok'] else 'FALLA'}"
              + (f" llm={'OK' if fila['llm_ok'] else 'FALLA'}" if llm else ""))
    prolog.cerrar()

    salida = RAIZ / "evaluacion"
    (salida / "resultados.json").write_text(json.dumps(filas, ensure_ascii=False, indent=1), encoding="utf-8")

    md = ["# Resultados de la evaluación\n"]
    cab = "| # | Categoría | Pregunta | Prolog | ¿OK? |" + (" LLM | ¿OK? |" if llm else "")
    md += [cab, "|" + "---|" * (cab.count("|") - 1)]
    celda = lambda s: s.replace("\n", "<br>").replace("|", "\\|")
    for f in filas:
        linea = f"| {f['id']} | {f['categoria']} | {f['pregunta']} | {celda(f['prolog'])} | {'✅' if f['prolog_ok'] else '❌'} |"
        if llm:
            linea += f" {celda(f['llm'])} | {'✅' if f['llm_ok'] else '❌'} |"
        md.append(linea)
    n = len(filas)
    md.append(f"\n**Prolog:** {sum(f['prolog_ok'] for f in filas)}/{n} aciertos automáticos.")
    if llm:
        md.append(f"\n**LLM:** {sum(f['llm_ok'] for f in filas)}/{n} aciertos automáticos.")
    (salida / "resultados.md").write_text("\n".join(md) + "\n", encoding="utf-8")
    print("Listo: evaluacion/resultados.json y resultados.md")


if __name__ == "__main__":
    main()
