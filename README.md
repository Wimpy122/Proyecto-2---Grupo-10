# Proyecto 2 – Chatbot de asistencia hotelera (Prolog + LLM)

Fundamentos de Inteligencia Artificial (CINF103).
Integrantes: Claudio González · Gabriel García · Moisés Pacheco
Docente: Jacqueline Köhler

Mismo dominio y **misma base de conocimiento** respondida de dos formas:
1. **Prolog** – lógica de primer orden (`prolog/hotel.pl`).
2. **LLM + Python** – el LLM recibe el conocimiento actual, exportado desde Prolog (`bots/llm_bot.py`).

Ambas se usan desde una interfaz web simple (`web/`) que permite comparar las respuestas lado a lado.

## Estructura
```
prolog/hotel.pl          Base de conocimiento, reglas, intérprete de texto libre, modo servidor
bots/prolog_bridge.py    Mantiene un proceso swipl vivo y le envía preguntas
bots/llm_bot.py          Chatbot LLM (API de Google Gemini) con el conocimiento en el prompt
web/app.py, templates/   Frontend Flask (modo Prolog / LLM / comparar)
evaluacion/              20 preguntas, script evaluar.py y resultados
INFORME.md               Informe de desempeño, conclusiones y propuestas de mejora
docs/README_entrega1.txt Documentación de la entrega 1 (dominio y modelado FOL)
```

## Requisitos y ejecución
- SWI-Prolog (`swipl` en el PATH) y Python 3.10+
- `pip install -r requirements.txt`

```bash
# Chatbot Prolog en consola
swipl prolog/hotel.pl
?- iniciar_chatbot.

# Interfaz web (Prolog + LLM)
export GEMINI_API_KEY=...           
python web/app.py                   # abrir http://127.0.0.1:5000

# Evaluación de 20 preguntas
python evaluacion/evaluar.py        # genera evaluacion/resultados.md y .json
python evaluacion/evaluar.py --solo-prolog
```
Modelo del LLM configurable con `LLM_MODEL` (por defecto `gemini-3.1-flash-lite`). La API key gratuita se crea en https://aistudio.google.com/apikey.

`ocupar 102` / `liberar 102` modifican el conocimiento en vivo; el LLM ve el cambio porque cada pregunta
vuelve a exportar el estado actual desde Prolog.
