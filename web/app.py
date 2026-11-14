# Claudio González - Gabriel Garcia - Moisés Pacheco

"""Frontend web simple (Flask) para los dos chatbots del hotel.

    pip install -r requirements.txt
    export GEMINI_API_KEY=...        
    python web/app.py                # http://127.0.0.1:5000
"""
import re
import sys
from pathlib import Path

from flask import Flask, jsonify, render_template, request

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from bots.llm_bot import LLMBot          # noqa: E402
from bots.prolog_bridge import PrologBot  # noqa: E402

app = Flask(__name__)
prolog = PrologBot()
llm = LLMBot(prolog)

# ocupar/liberar modifican el conocimiento: siempre se ejecutan en Prolog,
# y el LLM lee luego el estado actualizado.
COMANDO_ESTADO = re.compile(r"^\s*(ocupar|liberar)\s+\d+\s*$", re.IGNORECASE)


@app.get("/")
def index():
    return render_template("index.html")


@app.post("/api/preguntar")
def preguntar():
    datos = request.get_json(force=True)
    pregunta = (datos.get("pregunta") or "").strip()
    modo = datos.get("modo", "ambos")  # prolog | llm | ambos
    if not pregunta:
        return jsonify(error="Pregunta vacia"), 400

    if COMANDO_ESTADO.match(pregunta):
        return jsonify(prolog=prolog.preguntar(pregunta), llm=None, comando=True)

    resultado = {"prolog": None, "llm": None}
    if modo in ("prolog", "ambos"):
        resultado["prolog"] = prolog.preguntar(pregunta)
    if modo in ("llm", "ambos"):
        try:
            resultado["llm"] = llm.preguntar(pregunta)
        except Exception as e:  # sin API key, sin red, etc.
            resultado["llm"] = f"[Error LLM] {e}"
    return jsonify(resultado)

# uwu
@app.post("/api/reiniciar")
def reiniciar():
    prolog.reiniciar()
    return jsonify(ok=True)


if __name__ == "__main__":
    app.run(debug=False)
