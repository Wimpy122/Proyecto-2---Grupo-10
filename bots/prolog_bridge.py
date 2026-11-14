# Claudio González - Gabriel Garcia - Moisés Pacheco

"""Puente Python <-> Prolog.

Mantiene UN proceso `swipl` vivo (modo servidor de hotel.pl) y le envia
una pregunta por linea. Cada respuesta termina con la linea '<<FIN>>'.
Al mantener el proceso vivo, los cambios de estado (ocupar/liberar) persisten.
"""
import subprocess
import threading
from pathlib import Path

RUTA_PL = Path(__file__).resolve().parent.parent / "prolog" / "hotel.pl"
CENTINELA = "<<FIN>>"


class PrologBot:
    def __init__(self, ruta_pl=RUTA_PL, swipl="swipl"):
        self._ruta = str(ruta_pl)
        self._swipl = swipl
        self._lock = threading.Lock()
        self._proc = None
        self._iniciar()

    def _iniciar(self):
        self._proc = subprocess.Popen(
            [self._swipl, "-q", "-g", "servidor", "-t", "halt", self._ruta],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
            text=True, encoding="utf-8", bufsize=1,
        )

    def _enviar(self, linea):
        with self._lock:
            if self._proc.poll() is not None:
                self._iniciar()
            # una sola linea por mensaje
            linea = " ".join(linea.splitlines()).strip() or " "
            self._proc.stdin.write(linea + "\n")
            self._proc.stdin.flush()
            salida = []
            for l in self._proc.stdout:
                if l.strip() == CENTINELA:
                    break
                salida.append(l)
            return "".join(salida).strip()

    def preguntar(self, pregunta):
        """Responde una pregunta en texto libre usando la logica de primer orden."""
        return self._enviar(pregunta) or "No entendi tu pregunta."

    def exportar_conocimiento(self):
        """Devuelve la base de conocimiento ACTUAL (incluye ocupar/liberar) como texto."""
        return self._enviar("__EXPORTAR__")

    def reiniciar(self):
        """Vuelve el conocimiento al estado inicial del archivo .pl."""
        self.cerrar()
        self._iniciar()

    def cerrar(self):
        if self._proc and self._proc.poll() is None:
            self._proc.stdin.close()
            self._proc.terminate()
            self._proc.wait(timeout=5)
