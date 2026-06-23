"""Bot de conductor para DEMOS, fuera del MVP evaluado.

Este script NO es parte del producto MOTOLINK. Es una herramienta externa
que simula a un mototaxista siempre disponible, para poder presentar el
flujo completo (pasajero solicita -> recibe oferta -> selecciona -> viaja)
sin necesitar una segunda persona/dispositivo actuando como conductor real.

La app móvil y el backend siguen siendo 100% reales: este script solo hace
las mismas llamadas HTTP/Socket.IO que haría la app de un conductor humano,
desde afuera. Apagar este script no rompe nada; la negociación sigue
funcionando con conductores reales conectados desde la app.

Uso:
    python demo_driver_bot.py

Variables de entorno opcionales:
    MOTOLINK_BASE_URL      (default: http://127.0.0.1:8000)
    MOTOLINK_CONDUCTOR_ID  (default: usuario_id de "Carlos Conductor")
    MOTOLINK_DELAY_SEGUNDOS (default: 4, simula el tiempo real que tarda
                              un conductor humano en mirar y aceptar)
"""

import os
import random
import time

import requests
import socketio

BASE_URL = os.environ.get('MOTOLINK_BASE_URL', 'http://127.0.0.1:8000')
CONDUCTOR_ID = os.environ.get(
    'MOTOLINK_CONDUCTOR_ID', '8eb3a096-55b6-4ef1-87bc-2f51e129dcd1',
)
DELAY_SEGUNDOS = float(os.environ.get('MOTOLINK_DELAY_SEGUNDOS', '4'))

sio = socketio.Client()


@sio.event
def connect():
    print(f'[bot] conectado a {BASE_URL}, escuchando solicitudes nuevas...')
    sio.emit('join_room', {'room': 'conductores'})


@sio.event
def disconnect():
    print('[bot] desconectado')


@sio.on('SolicitudCreada')
def on_solicitud_creada(data):
    solicitud_id = data.get('id')
    origen = data.get('origen')
    destino = data.get('destino')
    tarifa = data.get('tarifaPropuesta')
    print(f'[bot] nueva solicitud {solicitud_id}: {origen} -> {destino} (S/ {tarifa})')

    espera = DELAY_SEGUNDOS + random.uniform(0, 2)
    print(f'[bot] simulando que el conductor está mirando ({espera:.1f}s)...')
    time.sleep(espera)

    url = f'{BASE_URL}/api/solicitudes-viaje/{solicitud_id}/aceptar/'
    headers = {'Host': '10.0.2.2:8000', 'Content-Type': 'application/json'}
    respuesta = requests.post(
        url, json={'conductor_id': CONDUCTOR_ID}, headers=headers,
    )
    if respuesta.status_code == 201:
        print(f'[bot] aceptada con tarifa propuesta por el pasajero (S/ {tarifa})')
    else:
        print(f'[bot] no se pudo aceptar ({respuesta.status_code}): {respuesta.text}')


if __name__ == '__main__':
    sio.connect(BASE_URL, headers={'Host': '10.0.2.2:8000'})
    sio.wait()
