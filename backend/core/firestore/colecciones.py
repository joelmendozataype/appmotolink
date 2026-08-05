"""Nombres de las colecciones en Firestore.

Equivalen a las tablas que existían en SQLite:

    users_usuario         -> usuarios
    users_mototaxista     -> mototaxistas
    trips_solicitudviaje  -> solicitudes_viaje
    trips_viaje           -> viajes
    negotiation_oferta    -> ofertas
    ratings_calificacion  -> calificaciones
"""

USUARIOS = 'usuarios'
MOTOTAXISTAS = 'mototaxistas'
SOLICITUDES = 'solicitudes_viaje'
VIAJES = 'viajes'
OFERTAS = 'ofertas'
CALIFICACIONES = 'calificaciones'

TODAS = (USUARIOS, MOTOTAXISTAS, SOLICITUDES, VIAJES, OFERTAS, CALIFICACIONES)
