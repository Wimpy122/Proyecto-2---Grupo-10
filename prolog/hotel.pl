:- encoding(utf8).
% PROYECTO N°2 - FUNDAMENTOS DE INTELIGENCIA ARTIFICIAL
% Chatbot de Asistencia Hotelera con Prolog
%
% Integrantes: Claudio González - Gabriel Garcia - Moisés Pacheco
%
% Uso:   swipl hotel.pl
%        ?- iniciar_chatbot.
%
% ---------------------------------------------------------------------
% Consultas directas para demostrar la logica (sin usar el chatbot):
%   ?- habitacion(N, suite, C, P).          % unificacion: busca todas las suites
%   ?- buscar_habitacion(2, Num, Tipo, P).  % backtracking: varias respuestas con ;
%   ?- tiene_servicio(302, spa).
%   ?- \+ tiene_servicio(101, spa).         % negacion por falla
%   ?- par_contiguo_libre(A, B).

:- dynamic estado/2.

% ------------------------------------
% 1. BASE DE CONOCIMIENTO (Hechos)

% habitacion(Numero, Tipo, Capacidad, PrecioPorNoche).
habitacion(101, simple, 1, 45000).
habitacion(102, doble,  2, 75000).
habitacion(201, doble,  2, 75000).
habitacion(202, doble,  2, 75000).
habitacion(301, suite,  4, 150000).
habitacion(302, suite,  4, 150000).

% estado(Numero, libre | ocupada).  (cambia en tiempo de ejecucion)
estado(101, ocupada).
estado(102, libre).
estado(201, libre).
estado(202, libre).
estado(301, ocupada).
estado(302, libre).

% incluye(TipoHabitacion, Servicio).
incluye(simple, wifi).
incluye(doble,  wifi).
incluye(doble,  desayuno).
incluye(suite,  wifi).
incluye(suite,  desayuno).
incluye(suite,  spa).

% adyacente(Num1, Num2): habitaciones contiguas (puerta con puerta).
adyacente(101, 102).
adyacente(201, 202).
adyacente(301, 302).

% politica(Tema, Texto). (datos de ejemplo: ajustar al hotel)
politica(checkin,     'El check-in es desde las 13:00.').
politica(checkout,    'El check-out es hasta las 12:00.').
politica(mascotas,    'No se permiten mascotas.').
politica(cancelacion, 'Cancelacion gratuita hasta 48 horas antes de la llegada.').

% -----------------------------------------------------
% 2. REGLAS LOGICAS

% forall n: Estado(n, libre) -> Disponible(n)
disponible(Num) :- estado(Num, libre).

% forall n: Estado(n, ocupada) -> Ocupada(n)
ocupada(Num) :- estado(Num, ocupada).

% Tipos de habitacion existentes (se derivan de los hechos).
tipo_habitacion(Tipo) :-
    setof(T, N^C^P^habitacion(N, T, C, P), Tipos),
    member(Tipo, Tipos).

% Instanciacion universal:
% forall n,t,s: Habitacion(n,t) ^ Incluye(t,s) -> TieneServicio(n,s)
tiene_servicio(Num, Servicio) :-
    habitacion(Num, Tipo, _, _),
    incluye(Tipo, Servicio).

% forall n,t,c,p,k: Habitacion(n,t,c,p) ^ c >= k ^ Disponible(n)
%                   -> Candidata(k,n,t,p)
buscar_habitacion(Personas, Num, Tipo, Precio) :-
    habitacion(Num, Tipo, Capacidad, Precio),
    Capacidad >= Personas,
    disponible(Num).

% Resultados ordenados de menor a mayor precio (lista de Precio-Num-Tipo).
habitaciones_para(Personas, Ordenadas) :-
    findall(Precio-Num-Tipo,
            buscar_habitacion(Personas, Num, Tipo, Precio), Lista),
    sort(0, @=<, Lista, Ordenadas).

% Una funcion devuelve un objeto; en Prolog se escribe como relacion:
% precio_total(n, k) = k * precio(n)
precio_total(Num, Noches, Total) :-
    habitacion(Num, _, _, PrecioNoche),
    Total is PrecioNoche * Noches.

% Un OR logico son varias clausulas con la misma cabeza (como ruido/2 en clase):
% Contiguas(x,y) <- Adyacente(x,y)  v  Adyacente(y,x)
contiguas(X, Y) :- adyacente(X, Y).
contiguas(X, Y) :- adyacente(Y, X).

% Dos habitaciones contiguas y libres (util para familias o grupos grandes).
par_contiguo_libre(A, B) :-
    adyacente(A, B),
    disponible(A),
    disponible(B).

% Cuantificadores:
%   exists n: Disponible(n)                  -> disponible(_)
%   forall n: Ocupada(n)  ==  not exists n: Disponible(n)   (\+ disponible(_))
%   forall n: TieneServicio(n,s) == not exists n: not TieneServicio(n,s)
hay_libres :- disponible(_).
todas_ocupadas :- \+ disponible(_).
todas_tienen(Servicio) :-
    \+ ( habitacion(Num, _, _, _), \+ tiene_servicio(Num, Servicio) ).

% Mundo cerrado: lo que no se puede probar se asume falso (negacion por falla).
sin_servicio(Num, Servicio) :-
    habitacion(Num, _, _, _),
    \+ tiene_servicio(Num, Servicio).

% Habitacion mas barata entre las libres (agregacion con findall + min).
mas_barata_libre(Num, Tipo, Precio) :-
    findall(P-N-T, (disponible(N), habitacion(N, T, _, P)), Lista),
    Lista \== [],
    sort(0, @=<, Lista, [Precio-Num-Tipo|_]).

% Conteos (agregacion con findall + length).
total_habitaciones(N) :- findall(X, habitacion(X, _, _, _), L), length(L, N).
total_libres(N)       :- findall(X, disponible(X), L), length(L, N).

% Modificacion del conocimiento en tiempo de ejecucion.
ocupar(Num) :-
    habitacion(Num, _, _, _),
    retractall(estado(Num, _)),
    assertz(estado(Num, ocupada)).

liberar(Num) :-
    habitacion(Num, _, _, _),
    retractall(estado(Num, _)),
    assertz(estado(Num, libre)).

% -------------------------------------------------
% 3. INTERPRETE DE PREGUNTAS (texto libre)

% normalizar(+Linea, -Palabras): minusculas, sin tildes ni signos, numeros como enteros.
normalizar(Linea, Palabras) :-
    string_lower(Linea, Min),
    string_codes(Min, Codigos),
    maplist(limpiar_codigo, Codigos, Limpios),
    string_codes(Texto, Limpios),
    split_string(Texto, " ", "", Partes0),
    exclude(==(""), Partes0, Partes),
    maplist(a_palabra, Partes, Palabras).

limpiar_codigo(C, L) :- tilde(C, L), !.
limpiar_codigo(C, 32) :- code_type(C, punct), !.
limpiar_codigo(C, C).

tilde(225, 0'a).  tilde(233, 0'e).  tilde(237, 0'i).
tilde(243, 0'o).  tilde(250, 0'u).  tilde(252, 0'u).
tilde(241, 0'n).

a_palabra(S, N) :- number_string(N, S), !.
a_palabra(S, A) :- atom_string(A, S).

sublista(Sub, Lista) :- append(_, Resto, Lista), append(Sub, _, Resto), !.

entero_en(P, N)  :- member(N, P), integer(N), !.

tipo_en(P, Tipo) :- member(W, P), tipo_palabra(W, Tipo), !.

tipo_palabra(W, T) :-
    atom(W),
    (   tipo_habitacion(W)                          -> T = W
    ;   atom_concat(T0, s, W), tipo_habitacion(T0)  -> T = T0
    ;   W == dobles                                 -> T = doble
    ).

servicio_en(P, S) :- member(S, P), atom(S), incluye(_, S), !.

noches_en(P, N) :-
    append(_, [N, Palabra|_], P),
    integer(N),
    memberchk(Palabra, [noche, noches]), !.
noches_en(_, 1).

personas_en(P, N) :-
    member(Palabra, [personas, persona]), memberchk(Palabra, P),
    member(N, P), integer(N), N > 0, \+ habitacion(N, _, _, _), !.
personas_en(P, N) :-
    append(_, [para, N|_], P), integer(N), N > 0, !.

todas_en(P) :- member(X, [todas, todos]), memberchk(X, P), !.

tema_politica(P, checkin) :-
    (   memberchk(checkin, P) ; sublista([check, in], P) ; memberchk(llegada, P) ), !.
tema_politica(P, checkout) :-
    (   memberchk(checkout, P) ; sublista([check, out], P) ; memberchk(salida, P) ), !.
tema_politica(P, mascotas) :-
    member(X, [mascotas, mascota, perro, perros, gato, gatos]), memberchk(X, P), !.
tema_politica(P, cancelacion) :-
    member(X, [cancelar, cancelacion, cancelo]), memberchk(X, P), !.

% interpretar(+Palabras, -Intencion): el orden de las clausulas importa.
interpretar(P, salir) :-
    member(X, [salir, chao, adios, exit]), memberchk(X, P), !.
interpretar(P, ayuda) :-
    member(X, [ayuda, help, opciones]), memberchk(X, P), !.
interpretar(P, ocupar(N)) :-
    memberchk(ocupar, P), entero_en(P, N), !.
interpretar(P, liberar(N)) :-
    memberchk(liberar, P), entero_en(P, N), !.
interpretar(P, explicar(Num, Personas)) :-
    member(X, [explica, explicar, justifica, demuestra]), memberchk(X, P),
    member(Num, P), integer(Num), habitacion(Num, _, _, _),
    personas_en(P, Personas), !.
interpretar(P, precio_hab(Num, Noches)) :-
    member(X, [precio, precios, cuesta, cuestan, costo, valor, cuanto]), memberchk(X, P),
    member(Num, P), integer(Num), habitacion(Num, _, _, _),
    noches_en(P, Noches), !.
interpretar(P, mas_barata) :-
    member(X, [barata, barato, economica, economico, menor]), memberchk(X, P), !.
interpretar(P, cuantas) :-
    member(X, [cuantas, cuantos]), memberchk(X, P),
    member(Y, [habitaciones, habitacion]), memberchk(Y, P), !.
interpretar(P, tiene(Num, S)) :-
    member(X, [tiene, incluye, cuenta, trae]), memberchk(X, P),
    member(Num, P), integer(Num), habitacion(Num, _, _, _),
    servicio_en(P, S), !.
interpretar(P, precio(Tipo, Noches)) :-
    member(X, [precio, precios, cuesta, cuestan, costo, valor, cuanto]), memberchk(X, P),
    tipo_en(P, Tipo), noches_en(P, Noches), !.
interpretar(P, buscar(N)) :-
    personas_en(P, N), !.
interpretar(P, estado(N)) :-
    member(X, [estado, libre, disponible, ocupada]), memberchk(X, P),
    entero_en(P, N), !.
interpretar(P, todas_ocupadas) :-
    todas_en(P), member(X, [ocupadas, ocupada, llenas, llena]), memberchk(X, P), !.
interpretar(P, todas_tienen(S)) :-
    todas_en(P), servicio_en(P, S), !.
interpretar(P, sin_servicio(S)) :-
    (   memberchk(sin, P) ; sublista([no, tienen], P) ; sublista([no, tiene], P)
    ;   sublista([no, incluyen], P) ; sublista([no, incluye], P) ),
    servicio_en(P, S), !.
interpretar(P, politica(Tema)) :-
    tema_politica(P, Tema), !.
interpretar(P, servicios_de(Tipo)) :-
    member(X, [servicios, servicio, incluye, incluido, incluidos]), memberchk(X, P),
    tipo_en(P, Tipo), !.
interpretar(P, contiguas) :-
    member(X, [contiguas, contiguo, contigua, juntas, cercanas, vecinas]), memberchk(X, P), !.
interpretar(P, con_servicio(S)) :-
    servicio_en(P, S), !.
interpretar(P, libres_tipo(Tipo)) :-
    member(X, [disponibles, disponible, libres, libre]), memberchk(X, P),
    tipo_en(P, Tipo), !.
interpretar(P, hay_libres) :-
    member(X, [hay, existe, queda, quedan]), memberchk(X, P),
    member(Y, [disponibles, disponible, libres, libre, habitaciones]), memberchk(Y, P), !.
interpretar(P, todos_servicios) :-
    member(X, [servicios, servicio]), memberchk(X, P), !.
interpretar(P, listar) :-
    member(X, [disponibles, libres, habitaciones, disponible]), memberchk(X, P), !.
interpretar(_, no_entendido).

% --------------------------------------------------------------------------------------
% 4. RESPUESTAS


responder(ayuda) :-
    writeln('Puedes preguntarme, por ejemplo:'),
    writeln('  - Que habitaciones estan disponibles? / Hay habitaciones libres?'),
    writeln('  - Necesito una habitacion para 3 personas'),
    writeln('  - Que servicios incluye la suite?'),
    writeln('  - Que habitaciones tienen spa? / Cuales no tienen spa?'),
    writeln('  - Todas las habitaciones tienen wifi?'),
    writeln('  - Estan todas ocupadas?'),
    writeln('  - Hay habitaciones contiguas libres?'),
    writeln('  - Cuanto cuesta una doble por 3 noches?'),
    writeln('  - Esta libre la habitacion 102?'),
    writeln('  - Explica por que la 302 sirve para 2 personas'),
    writeln('  - A que hora es el check-in? / Aceptan mascotas?'),
    writeln('  - ocupar 102 / liberar 102'),
    writeln('  - salir').

responder(listar) :-
    findall(P-N-T-C, (disponible(N), habitacion(N, T, C, P)), Lista),
    (   Lista == []
    ->  writeln('No hay habitaciones disponibles por ahora.')
    ;   writeln('Habitaciones disponibles:'),
        sort(0, @=<, Lista, Orden),
        forall(member(P-N-T-C, Orden),
               format('  Habitacion ~w (~w), capacidad ~w: $~w por noche~n', [N, T, C, P]))
    ).

% Cuantificador existencial.
responder(hay_libres) :-
    (   hay_libres
    ->  writeln('Si, existe al menos una habitacion libre.'),
        responder(listar)
    ;   writeln('No, por ahora no queda ninguna habitacion libre.')
    ).

% Cuantificador universal (forall = no existe un contraejemplo).
responder(todas_ocupadas) :-
    (   todas_ocupadas
    ->  writeln('Si, todas las habitaciones estan ocupadas.')
    ;   findall(N, disponible(N), Libres),
        format('No, hay habitaciones libres: ~w~n', [Libres])
    ).

responder(todas_tienen(S)) :-
    (   todas_tienen(S)
    ->  format('Si, todas las habitaciones incluyen ~w.~n', [S])
    ;   findall(N, sin_servicio(N, S), Sin),
        format('No, estas habitaciones no incluyen ~w: ~w~n', [S, Sin])
    ).

% Negacion por falla (mundo cerrado).
responder(sin_servicio(S)) :-
    findall(N, sin_servicio(N, S), Sin),
    (   Sin == []
    ->  format('Todas las habitaciones incluyen ~w.~n', [S])
    ;   format('Habitaciones que no incluyen ~w: ~w~n', [S, Sin])
    ).

responder(contiguas) :-
    findall(A-B, par_contiguo_libre(A, B), Pares),
    (   Pares == []
    ->  writeln('No hay pares de habitaciones contiguas libres por ahora.')
    ;   writeln('Pares de habitaciones contiguas libres:'),
        forall(member(A-B, Pares), format('  ~w y ~w~n', [A, B]))
    ).

responder(buscar(Personas)) :-
    habitaciones_para(Personas, Lista),
    (   Lista == []
    ->  format('No hay habitaciones disponibles para ~w persona(s).~n', [Personas])
    ;   format('Opciones para ~w persona(s), de menor a mayor precio:~n', [Personas]),
        forall(member(P-N-T, Lista),
               format('  Habitacion ~w (~w): $~w por noche~n', [N, T, P]))
    ).

responder(servicios_de(Tipo)) :-
    findall(S, incluye(Tipo, S), Servicios),
    (   Servicios == []
    ->  format('No tengo servicios registrados para ~w.~n', [Tipo])
    ;   format('La habitacion ~w incluye:~n', [Tipo]),
        forall(member(S, Servicios), format('  - ~w~n', [S]))
    ).

responder(con_servicio(S)) :-
    setof(T, incluye(T, S), Tipos),
    format('El servicio ~w esta incluido en: ~w.~n', [S, Tipos]),
    findall(N, (tiene_servicio(N, S), disponible(N)), Libres),
    (   Libres == []
    ->  writeln('Por ahora no hay habitaciones libres con ese servicio.')
    ;   format('Habitaciones libres con ~w: ~w~n', [S, Libres])
    ).

responder(todos_servicios) :-
    setof(S, T^incluye(T, S), Servicios),
    format('Servicios del hotel: ~w~n', [Servicios]).

responder(precio(Tipo, Noches)) :-
    findall(P, habitacion(_, Tipo, _, P), Precios),
    min_list(Precios, Min),
    Total is Min * Noches,
    format('Una habitacion ~w cuesta $~w por noche (~w noche(s): $~w).~n',
           [Tipo, Min, Noches, Total]).

responder(precio_hab(Num, Noches)) :-
    precio_total(Num, Noches, Total),
    habitacion(Num, Tipo, _, Precio),
    format('La habitacion ~w (~w) cuesta $~w por noche (~w noche(s): $~w).~n',
           [Num, Tipo, Precio, Noches, Total]).

responder(mas_barata) :-
    (   mas_barata_libre(N, T, P)
    ->  format('La habitacion libre mas barata es la ~w (~w): $~w por noche.~n', [N, T, P])
    ;   writeln('No hay habitaciones libres por ahora.')
    ).

responder(cuantas) :-
    total_habitaciones(T), total_libres(L),
    format('El hotel tiene ~w habitaciones; ~w estan libres.~n', [T, L]).

responder(tiene(Num, S)) :-
    (   tiene_servicio(Num, S)
    ->  format('Si, la habitacion ~w incluye ~w.~n', [Num, S])
    ;   format('No, la habitacion ~w no incluye ~w.~n', [Num, S])
    ).

responder(libres_tipo(Tipo)) :-
    findall(N-P, (habitacion(N, Tipo, _, P), disponible(N)), Lista),
    (   Lista == []
    ->  format('No hay habitaciones ~w libres por ahora.~n', [Tipo])
    ;   format('Habitaciones ~w libres:~n', [Tipo]),
        forall(member(N-P, Lista), format('  Habitacion ~w: $~w por noche~n', [N, P]))
    ).

responder(estado(Num)) :-
    (   \+ habitacion(Num, _, _, _)
    ->  format('La habitacion ~w no existe.~n', [Num])
    ;   estado(Num, E)
    ->  format('La habitacion ~w esta ~w.~n', [Num, E])
    ;   format('No tengo registro del estado de la habitacion ~w (mundo cerrado: no puedo afirmar que este libre).~n', [Num])
    ).

responder(ocupar(Num)) :-
    (   ocupar(Num)
    ->  format('Listo: la habitacion ~w ahora esta ocupada.~n', [Num])
    ;   format('La habitacion ~w no existe.~n', [Num])
    ).

responder(liberar(Num)) :-
    (   liberar(Num)
    ->  format('Listo: la habitacion ~w ahora esta libre.~n', [Num])
    ;   format('La habitacion ~w no existe.~n', [Num])
    ).

responder(politica(Tema)) :-
    politica(Tema, Texto),
    writeln(Texto).

% Muestra como Prolog prueba la meta (backward chaining, DFS de izquierda a derecha).
responder(explicar(Num, Personas)) :-
    explicar_busqueda(Num, Personas).

responder(no_entendido) :-
    writeln('No entendi tu pregunta. Escribe "ayuda" para ver ejemplos.').

explicar_busqueda(Num, Personas) :-
    format('Meta: buscar_habitacion(~w, ~w, Tipo, Precio)~n', [Personas, Num]),
    habitacion(Num, Tipo, Cap, Precio),
    format('  1. habitacion(~w, T, C, P) unifica con el hecho habitacion(~w, ~w, ~w, ~w): {T/~w, C/~w, P/~w}~n',
           [Num, Num, Tipo, Cap, Precio, Tipo, Cap, Precio]),
    (   Cap >= Personas
    ->  format('  2. ~w >= ~w es verdadero~n', [Cap, Personas]),
        (   disponible(Num)
        ->  format('  3. disponible(~w): existe el hecho estado(~w, libre)~n', [Num, Num]),
            format('Conclusion: VERDADERO, la habitacion ~w sirve para ~w persona(s).~n', [Num, Personas])
        ;   format('  3. disponible(~w) falla: no existe el hecho estado(~w, libre) (mundo cerrado)~n', [Num, Num]),
            writeln('Conclusion: FALSO.')
        )
    ;   format('  2. ~w >= ~w es falso: la regla falla antes de revisar el estado~n', [Cap, Personas]),
        writeln('Conclusion: FALSO.')
    ).

% .----------------------------------------------------------------------
% 5. CICLO PRINCIPAL

iniciar_chatbot :-
    writeln('======================================='),
    writeln('   Bienvenido al Asistente del Hotel'),
    writeln('======================================='),
    writeln('Escribe tu pregunta ("ayuda" para ver ejemplos, "salir" para terminar).'),
    ciclo.

ciclo :-
    write('> '), flush_output,
    read_line_to_string(user_input, Linea),
    (   Linea == end_of_file
    ->  despedir
    ;   normalizar(Linea, Palabras),
        (   Palabras == []
        ->  ciclo
        ;   interpretar(Palabras, Intencion),
            (   Intencion == salir
            ->  despedir
            ;   (   responder(Intencion) -> true
                ;   writeln('No pude responder eso.')
                ),
                nl,
                ciclo
            )
        )
    ).

despedir :-
    writeln('Gracias por preferirnos! Hasta luego.').

% -----------------------------------------------------------------
% 6. MODO SERVIDOR (lo usa el frontend web a traves de prolog_bridge.py)
% Lee una linea por pregunta y responde; cada respuesta termina con una
% linea centinela para que Python sepa donde acaba. El estado (ocupar/liberar)
% se mantiene mientras el proceso siga vivo.

centinela('<<FIN>>').

% Comando especial: vuelca el conocimiento actual como texto (lo usa el chatbot LLM).
exportar_conocimiento :-
    forall(habitacion(N, T, C, P),
           format('habitacion(~w, ~w, capacidad ~w, ~w CLP por noche)~n', [N, T, C, P])),
    forall(estado(N, E), format('estado(~w, ~w)~n', [N, E])),
    forall(incluye(T, S), format('incluye(~w, ~w)~n', [T, S])),
    forall(adyacente(A, B), format('adyacente(~w, ~w)~n', [A, B])),
    forall(politica(Tema, Texto), format('politica(~w): ~w~n', [Tema, Texto])).

servidor :-
    set_stream(user_input, encoding(utf8)),
    set_stream(user_output, encoding(utf8)),
    centinela(Fin),
    repeat,
        read_line_to_string(user_input, Linea),
        (   Linea == end_of_file
        ->  !
        ;   (   Linea == "__EXPORTAR__"
            ->  exportar_conocimiento
            ;   atender_linea(Linea)
            ),
            writeln(Fin), flush_output,
            fail
        ).

atender_linea(Linea) :-
    normalizar(Linea, Palabras),
    (   Palabras == []
    ->  true
    ;   interpretar(Palabras, Intencion),
        (   Intencion == salir
        ->  despedir
        ;   (   catch(responder(Intencion), _, fail) -> true
            ;   writeln('No pude responder eso.')
            )
        )
    ).
