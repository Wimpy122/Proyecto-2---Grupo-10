# Claudio González - Gabriel Garcia - Moisés Pacheco

"""Chatbot del hotel con un LLM (API de Google Gemini).

Usa el mismo conocimiento que la version Prolog: se lo
pedimos al proceso Prolog (exportar_conocimiento) y lo inyectamos en el
prompt de sistema. Asi ambas versiones son comparables y el estado
(habitaciones ocupadas/libres) siempre es consistente.

Variables de entorno:
    GEMINI_API_KEY   
    LLM_MODEL        
"""
import os
import time

import requests

from .prolog_bridge import PrologBot

MODELO_POR_DEFECTO = "gemini-3.1-flash-lite"
URL = "https://generativelanguage.googleapis.com/v1beta/models/{modelo}:generateContent"

PROMPT_SISTEMA = """Eres el asistente virtual de un hotel. Respondes preguntas de clientes sobre \
disponibilidad, capacidad, precios, servicios incluidos, politicas y habitaciones contiguas.

REGLAS:
1. Responde SOLO con la informacion de la BASE DE CONOCIMIENTO de abajo. No inventes habitaciones, \
precios, servicios ni politicas.
2. Si la pregunta no se puede responder con esa informacion (por ejemplo piscina, restaurante, \
vista al mar, o temas ajenos al hotel), dilo claramente: "No tengo esa informacion" y no adivines.
3. Los servicios se heredan del TIPO de habitacion (predicado incluye/2). Una habitacion esta \
disponible solo si su estado es 'libre'. Dos habitaciones son contiguas si hay un hecho adyacente/2 \
en cualquier orden. Los precios estan en pesos chilenos (CLP) por noche; si piden varias noches, multiplica.
4. Si no existe un hecho que lo respalde, asume que es falso (mundo cerrado).
5. Responde en espanol, breve y directo (maximo 4 lineas). Si haces calculos, muestralos de forma corta.

BASE DE CONOCIMIENTO (estado actual):
{conocimiento}
"""


class LLMBot:
    def __init__(self, prolog: PrologBot, modelo=None, http=None):
        self._prolog = prolog
        self.modelo = modelo or os.environ.get("LLM_MODEL", MODELO_POR_DEFECTO)
        self._http = http or requests  # se puede inyectar uno falso para pruebas

    def _llamar(self, sistema, pregunta):
        clave = os.environ.get("GEMINI_API_KEY")
        if not clave:
            raise RuntimeError("Falta la variable de entorno GEMINI_API_KEY para usar el chatbot LLM.")
        cuerpo = {
            "systemInstruction": {"parts": [{"text": sistema}]},
            "contents": [{"role": "user", "parts": [{"text": pregunta}]}],
            "generationConfig": {"temperature": 0, "maxOutputTokens": 1024},
        }
        for intento in range(4):
            r = self._http.post(URL.format(modelo=self.modelo), json=cuerpo, timeout=60,
                                headers={"x-goog-api-key": clave})
            if r.status_code in (429, 503) and intento < 3:   # limite del plan gratuito / sobrecarga
                time.sleep(5 * (intento + 1))
                continue
            if r.status_code != 200:
                raise RuntimeError(f"Gemini respondio {r.status_code}: {r.text[:200]}")
            break
        datos = r.json()
        try:
            partes = datos["candidates"][0]["content"]["parts"]
        except (KeyError, IndexError):
            return "[Sin respuesta del modelo (posible bloqueo de seguridad)]"
        return "".join(p.get("text", "") for p in partes).strip()

    def preguntar(self, pregunta):
        sistema = PROMPT_SISTEMA.format(conocimiento=self._prolog.exportar_conocimiento())
        return self._llamar(sistema, pregunta)
