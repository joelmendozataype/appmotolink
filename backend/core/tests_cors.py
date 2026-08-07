"""Orígenes permitidos para CORS.

Nace de un descuido real: el dominio que asigna la plataforma no se
conoce hasta que el servicio existe, así que había que copiarlo a mano a
una variable de entorno. Se olvidó, y durante días el dominio de
producción quedó fuera de la lista: la versión web no habría podido
llamar a su propia API.
"""
import importlib

from django.test import SimpleTestCase


def _cargar_settings(entorno):
    """Recarga settings.py con unas variables de entorno dadas."""
    import os

    from django.conf import settings as django_settings

    previas = {}
    for clave, valor in entorno.items():
        previas[clave] = os.environ.get(clave)
        if valor is None:
            os.environ.pop(clave, None)
        else:
            os.environ[clave] = valor
    try:
        modulo = importlib.import_module(django_settings.SETTINGS_MODULE)
        importlib.reload(modulo)
        return modulo
    finally:
        for clave, valor in previas.items():
            if valor is None:
                os.environ.pop(clave, None)
            else:
                os.environ[clave] = valor


class CorsTests(SimpleTestCase):
    def test_el_dominio_propio_se_agrega_solo(self):
        """Es el arreglo del descuido: aunque nadie lo configure, el
        servicio siempre se acepta a sí mismo."""
        s = _cargar_settings({
            'DJANGO_CORS_ORIGINS': None,
            'RENDER_EXTERNAL_HOSTNAME': 'motolink-api-arja.onrender.com',
            'DJANGO_DEBUG': 'False',
            'DJANGO_SECRET_KEY': 'clave-de-prueba-suficientemente-larga-123456',
        })
        self.assertIn(
            'https://motolink-api-arja.onrender.com', s.CORS_ALLOWED_ORIGINS,
        )
        self.assertFalse(s.CORS_ALLOW_ALL_ORIGINS)

    def test_convive_con_los_dominios_configurados(self):
        s = _cargar_settings({
            'DJANGO_CORS_ORIGINS': 'https://motolink.pe',
            'RENDER_EXTERNAL_HOSTNAME': 'motolink-api-arja.onrender.com',
            'DJANGO_DEBUG': 'False',
            'DJANGO_SECRET_KEY': 'clave-de-prueba-suficientemente-larga-123456',
        })
        self.assertIn('https://motolink.pe', s.CORS_ALLOWED_ORIGINS)
        self.assertIn(
            'https://motolink-api-arja.onrender.com', s.CORS_ALLOWED_ORIGINS,
        )

    def test_no_se_duplica_si_ya_estaba_configurado(self):
        s = _cargar_settings({
            'DJANGO_CORS_ORIGINS': 'https://motolink-api-arja.onrender.com',
            'RENDER_EXTERNAL_HOSTNAME': 'motolink-api-arja.onrender.com',
            'DJANGO_DEBUG': 'False',
            'DJANGO_SECRET_KEY': 'clave-de-prueba-suficientemente-larga-123456',
        })
        self.assertEqual(
            s.CORS_ALLOWED_ORIGINS.count('https://motolink-api-arja.onrender.com'),
            1,
        )

    def test_en_desarrollo_se_permite_cualquier_origen(self):
        """`flutter run -d chrome` usa un puerto distinto en cada arranque."""
        s = _cargar_settings({
            'DJANGO_CORS_ORIGINS': None,
            'RENDER_EXTERNAL_HOSTNAME': None,
            'DJANGO_DEBUG': 'True',
        })
        self.assertTrue(s.CORS_ALLOW_ALL_ORIGINS)

    def test_en_produccion_sin_ningun_origen_falla_el_arranque(self):
        """Mejor que el despliegue falle a que se levante aceptando a
        cualquiera con las credenciales activadas."""
        from django.core.exceptions import ImproperlyConfigured

        with self.assertRaises(ImproperlyConfigured):
            _cargar_settings({
                'DJANGO_CORS_ORIGINS': None,
                'RENDER_EXTERNAL_HOSTNAME': None,
                'DJANGO_DEBUG': 'False',
                'DJANGO_SECRET_KEY': 'clave-de-prueba-suficientemente-larga-123456',
            })

    def tearDown(self):
        # Devolver settings a su estado real: el módulo es global y una
        # recarga con valores de prueba afectaría a los demás tests.
        _cargar_settings({})
        super().tearDown()
