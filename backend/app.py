from flask import Flask, jsonify, request
import psycopg2
import os

app = Flask(__name__)


def get_connection():
    return psycopg2.connect(
        host=os.environ["DB_HOST"],
        database=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        port=5432
    )


@app.route("/")
def home():
    return jsonify({"mensaje": "Hola Juan - Backend funcionando"})


@app.route("/api/personas", methods=["GET"])
def obtener_personas():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute(
        "SELECT id, nombre, profesion FROM personas ORDER BY id"
    )

    personas = []

    for fila in cursor.fetchall():
        personas.append({
            "id": fila[0],
            "nombre": fila[1],
            "profesion": fila[2]
        })

    cursor.close()
    conn.close()

    return jsonify(personas)


@app.route("/api/personas", methods=["POST"])
def crear_persona():
    datos = request.get_json()

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute(
        """
        INSERT INTO personas (nombre, profesion)
        VALUES (%s, %s)
        RETURNING id
        """,
        (datos["nombre"], datos["profesion"])
    )

    nuevo_id = cursor.fetchone()[0]

    conn.commit()
    cursor.close()
    conn.close()

    return jsonify({
        "id": nuevo_id,
        "nombre": datos["nombre"],
        "profesion": datos["profesion"]
    }), 201


app.run(host="0.0.0.0", port=5000)
