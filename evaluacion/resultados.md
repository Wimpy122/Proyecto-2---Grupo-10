# Resultados de la evaluación

| # | Categoría | Pregunta | Prolog | ¿OK? | LLM | ¿OK? |
|---|---|---|---|---|---|---|
| 1 | Disponibilidad | ¿Qué habitaciones están disponibles? | Habitaciones disponibles:<br>  Habitacion 102 (doble), capacidad 2: $75000 por noche<br>  Habitacion 201 (doble), capacidad 2: $75000 por noche<br>  Habitacion 202 (doble), capacidad 2: $75000 por noche<br>  Habitacion 302 (suite), capacidad 4: $150000 por noche | ✅ | Las habitaciones disponibles actualmente son: 102, 201, 202 y 302. | ✅ |
| 2 | Capacidad | Necesito una habitación para 3 personas | Opciones para 3 persona(s), de menor a mayor precio:<br>  Habitacion 302 (suite): $150000 por noche | ✅ | La única habitación con capacidad para 3 o más personas es la suite (capacidad 4). Actualmente, la habitación 302 está libre y tiene un valor de 150.000 CLP por noche. | ✅ |
| 3 | Servicios | ¿Qué servicios incluye la suite? | La habitacion suite incluye:<br>  - wifi<br>  - desayuno<br>  - spa | ✅ | La suite incluye wifi, desayuno y spa. | ✅ |
| 4 | Servicios | ¿Qué habitaciones tienen spa? | El servicio spa esta incluido en: [suite].<br>Habitaciones libres con spa: [302] | ✅ | Las habitaciones tipo suite incluyen spa. Actualmente, la habitación 302 es la única suite disponible. | ✅ |
| 5 | Negación (mundo cerrado) | ¿Cuáles no tienen spa? | Habitaciones que no incluyen spa: [101,102,201,202] | ✅ | Las habitaciones simple (101) y doble (102, 201, 202) no incluyen spa. Solo las habitaciones tipo suite incluyen ese servicio. | ✅ |
| 6 | Cuantificador universal | ¿Todas las habitaciones tienen wifi? | Si, todas las habitaciones incluyen wifi. | ✅ | Sí, todas las habitaciones (simple, doble y suite) incluyen servicio de wifi. | ✅ |
| 7 | Cuantificador universal | ¿Están todas las habitaciones ocupadas? | No, hay habitaciones libres: [102,201,202,302] | ✅ | No, no todas están ocupadas. Las habitaciones 102, 201, 202 y 302 se encuentran actualmente libres. | ✅ |
| 8 | Relaciones | ¿Hay habitaciones contiguas libres? | Pares de habitaciones contiguas libres:<br>  201 y 202 | ✅ | Sí, las habitaciones 201 y 202 son contiguas y ambas están libres. También las habitaciones 102 y 202 están libres, pero no son contiguas entre sí. | ✅ |
| 9 | Precios | ¿Cuánto cuesta una doble por 3 noches? | Una habitacion doble cuesta $75000 por noche (3 noche(s): $225000). | ✅ | Una habitación doble cuesta 75.000 CLP por noche. Por 3 noches, el total es 225.000 CLP. | ✅ |
| 10 | Estado | ¿Puedo reservar la 102 para hoy? | No entendi tu pregunta. Escribe "ayuda" para ver ejemplos. | ❌ | Sí, la habitación 102 está libre. Su valor es de 75.000 CLP por noche e incluye wifi y desayuno. | ✅ |
| 11 | Explicación | Explica por qué la 302 sirve para 2 personas | Meta: buscar_habitacion(2, 302, Tipo, Precio)<br>  1. habitacion(302, T, C, P) unifica con el hecho habitacion(302, suite, 4, 150000): {T/suite, C/4, P/150000}<br>  2. 4 >= 2 es verdadero<br>  3. disponible(302): existe el hecho estado(302, libre)<br>Conclusion: VERDADERO, la habitacion 302 sirve para 2 persona(s). | ✅ | La habitación 302 es de tipo suite, la cual tiene una capacidad máxima de 4 personas. Por lo tanto, es apta para hospedar a 2 personas. | ✅ |
| 12 | Políticas | ¿A qué hora es el check-in? | El check-in es desde las 13:00. | ✅ | El check-in es desde las 13:00. | ✅ |
| 13 | Políticas | ¿Puedo llevar a mi loro? | No entendi tu pregunta. Escribe "ayuda" para ver ejemplos. | ❌ | No, no se permiten mascotas en el hotel. | ✅ |
| 14 | Razonamiento | ¿Cuál es la habitación libre más barata? | La habitacion libre mas barata es la 102 (doble): $75000 por noche. | ✅ | La habitación libre más barata es la 102 (doble) a 75.000 CLP por noche. | ❌ |
| 15 | Razonamiento | ¿La 101 tiene desayuno? | No, la habitacion 101 no incluye desayuno. | ✅ | No, la habitación 101 es de tipo simple y solo incluye wifi. No incluye desayuno. | ✅ |
| 16 | Precios | ¿Cuánto cuesta la 301 por 2 noches? | La habitacion 301 (suite) cuesta $150000 por noche (2 noche(s): $300000). | ✅ | La habitación 301 se encuentra ocupada actualmente, por lo que no está disponible para reserva. | ❌ |
| 17 | Lenguaje natural | Somos una familia de 4 y queremos dos habitaciones juntas, ¿tienen? | Pares de habitaciones contiguas libres:<br>  201 y 202 | ✅ | Sí, tenemos disponibles las habitaciones 201 y 202, que son contiguas y tienen capacidad para 2 personas cada una. El costo total por noche es de 150.000 CLP (75.000 CLP por cada una). | ✅ |
| 18 | Razonamiento | Llego mañana y mi plan cambió, ¿puedo cancelar gratis el día anterior? | Cancelacion gratuita hasta 48 horas antes de la llegada. | ❌ | No, la política de cancelación gratuita es hasta 48 horas antes de la llegada. No es posible cancelar gratis el día anterior. | ✅ |
| 19 | Fuera de la base | ¿Tienen piscina? | No entendi tu pregunta. Escribe "ayuda" para ver ejemplos. | ✅ | No tengo esa información. | ✅ |
| 20 | Fuera del dominio | ¿Cuál es la capital de Francia? | No entendi tu pregunta. Escribe "ayuda" para ver ejemplos. | ✅ | No tengo esa información. | ✅ |

**Prolog:** 17/20 aciertos automáticos.

**LLM:** 18/20 aciertos automáticos.
