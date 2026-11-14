PROYECTO N°2 - FUNDAMENTOS DE INTELIGENCIA ARTIFICIAL (CINF103)
Chatbot de asistencia hotelera en Prolog - Entrega 1

Integrantes: Claudio Gonzalez, Gabriel Garcia, Moises Pacheco

----------------------------------------------------------------------
1. DOMINIO
----------------------------------------------------------------------
Dominio: hotel (reservas y consultas de habitaciones).
No esta relacionado con la informatica, como pide el enunciado.

Por que lo elegimos: (completar con las razones del grupo; ejemplos:
es un dominio cotidiano que todos entienden, tiene objetos claros
(habitaciones, servicios) y relaciones que se pueden razonar con reglas,
y las preguntas de los clientes son faciles de modelar.)

El chatbot responde preguntas sobre disponibilidad, capacidad, precios,
servicios incluidos, politicas del hotel y habitaciones contiguas.

----------------------------------------------------------------------
2. MODELADO EN LOGICA DE PRIMER ORDEN
----------------------------------------------------------------------
Objetos (constantes): numeros de habitacion (101, 102, ...), tipos
(simple, doble, suite), servicios (wifi, desayuno, spa).

Hechos (predicados):
  habitacion(Num, Tipo, Capacidad, PrecioPorNoche)
  estado(Num, libre | ocupada)        % dinamico: cambia en ejecucion
  incluye(Tipo, Servicio)
  adyacente(Num1, Num2)               % habitaciones contiguas
  politica(Tema, Texto)

Reglas (formula de primer orden -> Prolog):
  para todo n: Estado(n, libre) -> Disponible(n)
      disponible(Num) :- estado(Num, libre).

  para todo n,t,s: Habitacion(n,t) ^ Incluye(t,s) -> TieneServicio(n,s)
      tiene_servicio(Num, S) :- habitacion(Num, Tipo, _, _), incluye(Tipo, S).

  para todo n,t,c,p,k: Habitacion(n,t,c,p) ^ c >= k ^ Disponible(n)
                       -> Candidata(k,n,t,p)
      buscar_habitacion(K, Num, Tipo, Precio) :-
          habitacion(Num, Tipo, Cap, Precio), Cap >= K, disponible(Num).

  Contiguas(x,y) <- Adyacente(x,y) v Adyacente(y,x)
      contiguas(X, Y) :- adyacente(X, Y).
      contiguas(X, Y) :- adyacente(Y, X).

  Cuantificadores:
      existe n: Disponible(n)                  -> hay_libres
      para todo n: Ocupada(n) == no existe n: Disponible(n)
                                               -> todas_ocupadas
      para todo n: TieneServicio(n,s)          -> todas_tienen(S)

  Mundo cerrado: lo que no se puede probar se asume falso (negacion por
  falla, \+). Se usa en sin_servicio/2 y en el estado de una habitacion
  sin registro.

Inferencia: Prolog usa backward chaining (DFS de izquierda a derecha con
backtracking). El comando "explicar" del chatbot muestra la prueba paso
a paso con las sustituciones de la unificacion.

----------------------------------------------------------------------
3. CHATBOT EN PROLOG
----------------------------------------------------------------------
Requisito: SWI-Prolog.

Ejecucion:
    swipl codigo4.pl
    ?- iniciar_chatbot.

El chatbot acepta preguntas en texto libre (sin necesidad de tildes ni
punto final). Escribir "ayuda" muestra ejemplos y "salir" termina.

Ejemplos:
  - Que habitaciones estan disponibles?
  - Necesito una habitacion para 3 personas
  - Que servicios incluye la suite?
  - Que habitaciones tienen spa? / Cuales no tienen spa?
  - Todas las habitaciones tienen wifi?
  - Estan todas ocupadas?
  - Hay habitaciones contiguas libres?
  - Cuanto cuesta una doble por 3 noches?
  - Esta libre la habitacion 102?
  - Explica por que la 302 sirve para 2 personas
  - A que hora es el check-in? / Aceptan mascotas?
  - ocupar 102 / liberar 102   (modifica el conocimiento en vivo)

Consultas directas en Prolog (sin el chatbot):
  ?- habitacion(N, suite, C, P).
  ?- buscar_habitacion(2, Num, Tipo, Precio).
  ?- tiene_servicio(302, spa).
  ?- \+ tiene_servicio(101, spa).
  ?- par_contiguo_libre(A, B).
