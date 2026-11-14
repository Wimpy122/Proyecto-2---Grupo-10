"""Diagnostico de Gemini: lista los modelos disponibles para tu clave y mide cuanto tarda cada uno.

    $env:GEMINI_API_KEY="tu_clave"
    python probar_gemini.py              # lista modelos y prueba los 'flash'
    python probar_gemini.py nombre-modelo  # prueba solo ese modelo
"""
import os
import sys
import time

import requests

clave = os.environ.get("GEMINI_API_KEY")
if not clave:
    sys.exit("Falta GEMINI_API_KEY en esta terminal.")
H = {"x-goog-api-key": clave}
BASE = "https://generativelanguage.googleapis.com/v1beta"

if len(sys.argv) > 1:
    modelos = [sys.argv[1].replace("models/", "")]
else:
    r = requests.get(f"{BASE}/models?pageSize=200", headers=H, timeout=30)
    if r.status_code != 200:
        sys.exit(f"Error {r.status_code}: {r.text[:300]}")
    todos = [m["name"].replace("models/", "") for m in r.json().get("models", [])
             if "generateContent" in m.get("supportedGenerationMethods", [])]
    print("Modelos con generateContent:\n  " + "\n  ".join(todos))
    modelos = [m for m in todos if "flash" in m and "preview" not in m][:6]
    print("\nProbando:", modelos)

for m in modelos:
    t0 = time.perf_counter()
    try:
        r = requests.post(f"{BASE}/models/{m}:generateContent", headers=H, timeout=90, json={
            "contents": [{"role": "user", "parts": [{"text": "Responde solo: ok"}]}],
            "generationConfig": {"temperature": 0, "maxOutputTokens": 64}})
        seg = time.perf_counter() - t0
        if r.status_code == 200:
            try:
                txt = r.json()["candidates"][0]["content"]["parts"][0]["text"].strip()
            except Exception:
                txt = "(sin texto)"
            print(f"OK   {m:35} {seg:5.1f}s -> {txt}")
        else:
            print(f"ERR  {m:35} {seg:5.1f}s HTTP {r.status_code}: {r.json().get('error', {}).get('message', '')[:120]}")
    except requests.RequestException as e:
        print(f"FALLA {m:34} {time.perf_counter() - t0:5.1f}s {type(e).__name__}")
