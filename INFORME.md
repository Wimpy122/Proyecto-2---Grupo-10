# Informe de desempeño – Chatbot de asistencia hotelera

**Proyecto N°2 – Fundamentos de Inteligencia Artificial** · Claudio González, Gabriel García, Moisés Pacheco
**Docente:** Jacqueline Köhler
## 1. Dominio y sistemas comparados
Dominio: hotel (reservas y consultas de habitaciones). *Motivo de la elección:* es un dominio cotidiano que todos entienden, tiene objetos claros (habitaciones, servicios) y relaciones que se pueden razonar con reglas, y las preguntas de los clientes son fáciles de modelar.
Base de conocimiento: 6 habitaciones (`habitacion/4`), su estado
(`estado/2`, dinámico), servicios por tipo (`incluye/2`), habitaciones contiguas (`adyacente/2`) y políticas (`politica/2`).

| | Versión Prolog | Versión LLM |
|---|---|---|
| Conocimiento | Hechos y reglas FOL | Los mismos hechos, exportados como texto al prompt |
| Comprensión del texto | Reglas `interpretar/2` por palabras clave | El propio LLM |
| Razonamiento | Backward chaining, unificación, negación por falla | Implícito en el modelo, guiado por reglas del prompt |
| Estado vivo | `ocupar/liberar` con `assert/retract` | Lee el estado actual en cada pregunta |

## 2. Metodología
20 preguntas en 14 categorías (disponibilidad, capacidad, servicios, negación, cuantificador universal, relaciones, precios, estado, explicación,
políticas, razonamiento, lenguaje natural, fuera de la base y fuera del dominio). Estado inicial: 101 y 301 ocupadas. Cada respuesta se compara con una respuesta esperada
(`evaluacion/preguntas.json`). LLM `gemini-3.1-flash-lite` con `temperature=0`, una sola ejecución.

**Sesgo a declarar:** durante el desarrollo se detectaron fallas del bot Prolog con preguntas similares a las del set
(p. ej. «¿Cuáles no tienen spa?», «¿La 101 tiene desayuno?») y se agregaron intenciones para corregirlas. Por eso los
aciertos de Prolog en esas preguntas reflejan en parte ajuste al set; las preguntas 10, 13 y 18 se redactaron *después*
con formulaciones nuevas para medir la generalización.

## 3. Resultados
Modelo LLM usado: **gemini-3.1-flash-lite** (`temperature=0`, una sola ejecución). Revisión manual de cada respuesta:
**Prolog 17/20 · LLM 19/20.** (El chequeo automático dio 18/20 al LLM porque en la pregunta 14 buscaba «75000» y el modelo escribió «75.000»:
es un falso negativo del script, la respuesta es correcta.)

| # | Pregunta | Prolog | ✔ | LLM | ✔ |
|---|---|---|---|---|---|
| 1 | ¿Qué habitaciones están disponibles? | Lista 102, 201, 202, 302 con tipo, capacidad y precio | ✅ | «102, 201, 202 y 302» | ✅ |
| 2 | Necesito una habitación para 3 personas | 302 (suite, $150000) | ✅ | Suite 302, libre, 150.000 CLP | ✅ |
| 3 | ¿Qué servicios incluye la suite? | wifi, desayuno, spa | ✅ | wifi, desayuno y spa | ✅ |
| 4 | ¿Qué habitaciones tienen spa? | Tipo suite; libres: [302] | ✅ | Las suites; la única libre es la 302 | ✅ |
| 5 | ¿Cuáles no tienen spa? | [101,102,201,202] | ✅ | Simple (101) y dobles (102, 201, 202) | ✅ |
| 6 | ¿Todas tienen wifi? | Sí, todas | ✅ | Sí, simple, doble y suite | ✅ |
| 7 | ¿Están todas ocupadas? | No, libres: [102,201,202,302] | ✅ | No; libres 102, 201, 202 y 302 | ✅ |
| 8 | ¿Hay habitaciones contiguas libres? | 201 y 202 | ✅ | 201 y 202; añade un comentario innecesario y confuso sobre 102 y 202 | ✅ |
| 9 | ¿Cuánto cuesta una doble por 3 noches? | $75000/noche, total $225000 | ✅ | 75.000 CLP/noche, total 225.000 | ✅ |
| 10 | ¿Puedo reservar la 102 para hoy? | «No entendí tu pregunta» | ❌ | Sí, está libre, 75.000 CLP, wifi y desayuno | ✅ |
| 11 | Explica por qué la 302 sirve para 2 personas | Traza completa: unificación, 4>=2, estado libre → VERDADERO | ✅ | Suite de capacidad 4, apta para 2 (no menciona que esté libre) | ✅ |
| 12 | ¿A qué hora es el check-in? | Desde las 13:00 | ✅ | Desde las 13:00 | ✅ |
| 13 | ¿Puedo llevar a mi loro? | «No entendí tu pregunta» | ❌ | No, no se permiten mascotas | ✅ |
| 14 | ¿Cuál es la habitación libre más barata? | 102 (doble), $75000 | ✅ | 102 (doble), 75.000 CLP | ✅ |
| 15 | ¿La 101 tiene desayuno? | No | ✅ | No: es simple y solo incluye wifi | ✅ |
| 16 | ¿Cuánto cuesta la 301 por 2 noches? | $300000 | ✅ | «La 301 está ocupada, no está disponible para reserva» (no da el precio) | ❌ |
| 17 | Somos 4 y queremos dos habitaciones juntas | 201 y 202 | ✅ | 201 y 202, 150.000 CLP por noche en total | ✅ |
| 18 | ¿Puedo cancelar gratis el día anterior? | Repite la política (48 h) sin concluir | ❌ | No: la gratuita es hasta 48 h antes | ✅ |
| 19 | ¿Tienen piscina? | «No entendí tu pregunta» | ✅* | «No tengo esa información» | ✅ |
| 20 | ¿Cuál es la capital de Francia? | «No entendí tu pregunta» | ✅* | «No tengo esa información» | ✅ |

\* No inventa, pero la respuesta no distingue «fuera de tema» de «no reconocí la frase».
Respuestas completas: `evaluacion/resultados.md`.

## 4. Análisis del desempeño
**Prolog (17/20).** Respuestas exactas y deterministas en todo lo que su intérprete reconoce, incluyendo cuantificadores (∃ y ∀ vía
`\+`), negación por falla, cálculos y la traza de prueba (pregunta 11), que el LLM no entrega de forma verificable. Sus 3 fallas
son de comprensión del lenguaje y de razonamiento sobre texto, no de lógica: (10) no reconoce «reservar» como consulta de
disponibilidad; (13) vocabulario cerrado, «loro» no está en la lista de mascotas; (18) cita la política pero no concluye sobre ella,
porque no hay hechos de fechas o plazos. Ante preguntas fuera de la base (19, 20) responde «No entendí», sin inventar.

**LLM, gemini-3.1-flash-lite (19/20).** Entendió todas las paráfrasis (10, 13, 17, 18) y razonó sobre la política de cancelación, justo
donde Prolog falló. Su única falla (16) fue un error de interpretación: la 301 está ocupada, pero la pregunta era por su precio,
y el modelo respondió sobre disponibilidad sin dar el dato que sí tenía. Es un error de razonamiento que Prolog, al calcular
`precio_total/3`, no comete. Además, en la pregunta 8 agregó un comentario innecesario y confuso, y en la 11 omitió verificar que la 302
estuviera libre. En las preguntas 19 y 20 respondió «No tengo esa información», más claro para el usuario que el «No entendí» de Prolog.

**Comparación.** Ambos aciertan en 16 preguntas. Prolog solo falla donde el lenguaje se sale de su gramática, y el LLM solo donde
interpretó mal lo que se pedía. Con un set de 20 preguntas y una sola ejecución la diferencia (17 vs 19) no es concluyente.
Las preguntas 10, 13 y 18 se redactaron después de ajustar Prolog, y ahí está la mayor parte de su ventaja.

## 5. Fortalezas y debilidades
| | Prolog | LLM (Gemini) |
|---|---|---|
| Fortalezas | Exacto y reproducible; explicable (`explicar`); sin costo ni red; no alucina; instantáneo; modifica el conocimiento en vivo | Entiende paráfrasis y vocabulario libre; respuestas naturales; razona sobre políticas; admite claramente que no sabe |
| Debilidades | Parsing frágil (palabras clave, orden de cláusulas); vocabulario cerrado; cada pregunta nueva exige código; «No entendí» poco informativo; no razona sobre texto libre | No determinista en general (aunque `temperature=0`); puede interpretar mal la pregunta (16) o agregar ruido (8); depende de red, API, cuota y disponibilidad (probamos modelos con errores 404, 429 y 503); latencia de segundos; el conocimiento completo viaja en cada llamada, no escala |

## 6. Conclusiones
El razonamiento lógico y la comprensión del lenguaje son capacidades complementarias: Prolog es confiable donde la pregunta
cae en su gramática, y el LLM es robusto a la forma de la pregunta pero menos garantizado en el fondo. Para un hotel real
conviene combinarlos (sección 7).

## 7. Propuestas de mejora
1. **Arquitectura híbrida:** el LLM traduce la pregunta a una consulta Prolog (intención + argumentos), Prolog responde con
   exactitud y el LLM redacta la respuesta. Une comprensión flexible con respuestas verificables.
2. **Mejorar el NLU de Prolog:** sinónimos (reservar, pieza, cuarto), lematización simple, tabla de mascotas ampliada y
   gramática DCG en lugar de palabras clave.
3. **Corregir los fallos observados del LLM:** pedir en el prompt que responda siempre el dato preguntado aunque la habitación esté ocupada (pregunta 16)
   y comparar con un modelo mayor.
4. **Razonamiento sobre fechas:** modelar reservas (`reserva(Hab, Entrada, Salida)`) y plazos para responder preguntas como la 18
   y disponibilidad por fechas.
5. **Fundamentar al LLM:** pedir citas de los hechos usados, validar numéricos con código y *tool calling* a Prolog para cálculos.
6. **Más conocimiento y pruebas:** más habitaciones, tarifas por temporada, y un set de evaluación mayor con jueces distintos al autor.
7. **Seguridad:** el LLM no debe poder ejecutar `ocupar/liberar` sin autenticación.
