from flask import Flask, request, render_template_string

app = Flask(__name__)

# IP interna que tiene el Nodo Escudo dentro del tunel
IP_TUNEL_ESCUDO = "10.0.0.1"

HTML_PAGINA = """
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Monitor del Servidor de Oficina</title>
    <style>
        body {
            background-color: #0f172a;
            color: #e2e8f0;
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 30px;
        }
        .contenedor {
            max-width: 900px;
            margin: 0 auto;
        }
        h1 {
            border-bottom: 1px solid #334155;
            padding-bottom: 12px;
            font-size: 24px;
        }
        .tarjetas {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
            margin-top: 20px;
            margin-bottom: 25px;
        }
        .tarjeta {
            background-color: #1e293b;
            border: 1px solid #334155;
            border-radius: 8px;
            padding: 18px;
        }
        .titulo-tarjeta {
            font-size: 13px;
            color: #94a3b8;
            margin-bottom: 8px;
        }
        .valor {
            font-size: 20px;
            font-weight: bold;
            color: #38bdf8;
        }
        .activo {
            color: #4ade80;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            background-color: #1e293b;
            border: 1px solid #334155;
            border-radius: 8px;
            overflow: hidden;
        }
        th, td {
            text-align: left;
            padding: 10px 14px;
            border-bottom: 1px solid #334155;
            font-size: 14px;
        }
        th {
            background-color: #0f172a;
            color: #94a3b8;
        }
        .nota {
            margin-top: 20px;
            font-size: 13px;
            color: #94a3b8;
        }
    </style>
</head>
<body>
    <div class="contenedor">
        <h1>Panel de Auditoria - Servidor en Oficina Central</h1>

        <div class="tarjetas">
            <div class="tarjeta">
                <div class="titulo-tarjeta">Estado del Tunel Seguro</div>
                <div class="valor activo">{{ estado_tunel }}</div>
            </div>

            <div class="tarjeta">
                <div class="titulo-tarjeta">IP Interna que Entrega el Paquete</div>
                <div class="valor">{{ ip_interna }}</div>
            </div>

            <div class="tarjeta">
                <div class="titulo-tarjeta">IP Publica del Visitante (X-Forwarded-For)</div>
                <div class="valor">{{ ip_visitante }}</div>
            </div>
        </div>

        <h2>Cabeceras HTTP Recibidas en la Oficina</h2>
        <table>
            <thead>
                <tr>
                    <th>Cabecera</th>
                    <th>Valor</th>
                </tr>
            </thead>
            <tbody>
                {% for nombre, valor in cabeceras %}
                <tr>
                    <td>{{ nombre }}</td>
                    <td>{{ valor }}</td>
                </tr>
                {% endfor %}
            </tbody>
        </table>

        <p class="nota">
            Nota: El trafico llega desde el Nodo Escudo (10.0.0.1) hacia este servidor (10.0.0.2:8000).
            La IP publica real de la oficina no se expone en ningun momento.
        </p>
    </div>
</body>
</html>
"""


@app.route("/")
def inicio():
    # IP que nos entrega el paquete directamente por la red
    ip_que_entrega = request.remote_addr

    # Si alguien intenta entrar sin pasar por el tunel (10.0.0.1), lo rechazamos
    if ip_que_entrega != IP_TUNEL_ESCUDO and ip_que_entrega != "127.0.0.1":
        return "Acceso bloqueado: solo se permiten conexiones desde el tunel (10.0.0.1)", 403

    if ip_que_entrega == IP_TUNEL_ESCUDO:
        estado_tunel = "Activo / Aislado"
    else:
        estado_tunel = "Prueba Local (Loopback)"

    # Leemos la IP del visitante que nos manda Nginx en X-Forwarded-For
    ip_visitante = request.headers.get("X-Forwarded-For", "No detectada")

    cabeceras = list(request.headers.items())

    respuesta = app.make_response(
        render_template_string(
            HTML_PAGINA,
            estado_tunel=estado_tunel,
            ip_interna=ip_que_entrega,
            ip_visitante=ip_visitante,
            cabeceras=cabeceras,
        )
    )

    # Agregamos estas cabeceras a proposito para comprobar que Nginx las borra
    respuesta.headers["Server"] = "Servidor-Interno-Oficina"
    respuesta.headers["X-Powered-By"] = "Flask-Python"
    return respuesta


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
