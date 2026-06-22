# Backlog — funcionalidades postergadas

Estas funcionalidades estaban contempladas como carpetas vacías en la
estructura inicial del proyecto, pero **no pertenecen al MVP** (negociación
pasajero↔conductor con tarifas). Se eliminaron de `mobile/lib/features/` para
no inflar la estructura con código muerto; quedan documentadas aquí como
trabajo futuro explícito, no descartado.

| Funcionalidad | Descripción | Justificación de postergación |
|---|---|---|
| `chat` | Mensajería en tiempo real entre pasajero y conductor durante la negociación/viaje | El MVP ya cubre la negociación vía ofertas/contraofertas estructuradas; un chat libre es una mejora de UX posterior, no un requisito del flujo core |
| `wallet` | Billetera digital / pagos dentro de la app | Pagos están explícitamente fuera de alcance del MVP (se paga en efectivo entre las partes) |
| `support` | Centro de ayuda / soporte al usuario | No es parte del flujo de negociación; útil para una versión productiva |
| `notifications` | Notificaciones push nativas (más allá de los eventos Socket.IO ya implementados) | Los eventos en tiempo real (`SolicitudCreada`, `OfertaCreada`, etc.) ya cubren la necesidad inmediata dentro de la app abierta; push fuera de la app requiere FCM/APNs, que es trabajo adicional de infraestructura |

## Cuándo retomarlas

Tras cerrar la integración móvil↔backend del MVP (ya completada) y con el
flujo principal estable en producción, en ese orden de prioridad:
`notifications` (push) → `chat` → `support` → `wallet`.
