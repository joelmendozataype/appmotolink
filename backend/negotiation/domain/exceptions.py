class SolicitudNoDisponibleError(Exception):
    """La solicitud ya fue aceptada, cancelada o finalizada."""


class OfertaDuplicadaError(Exception):
    """El conductor ya respondió a esta solicitud."""


class OfertaNoDisponibleError(Exception):
    """La oferta ya fue aceptada o rechazada por el pasajero."""
