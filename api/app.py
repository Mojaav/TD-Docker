# API 

from flask import Flask, jsonify, request
import psycopg2
import os

app = Flask(__name__)

# Variables d'env pour la connexion DB
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "password")
DB_NAME = os.getenv("DB_NAME", "mydb")
HTTP_PORT = int(os.getenv("HTTP_PORT", "5000"))

def get_db_connection():
    """Crée une connexion à la base de données PostgreSQL"""
    conn = psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME
    )
    return conn

@app.route('/status')
def status():
    """Route /status - Vérifie que l'API fonctionne"""
    return jsonify({"status": "OK", "message": "L'API est disponible!"})

@app.route('/items')
def get_items():
    """Route /items - Récupère la liste des items depuis la DB"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT id, nom, description, date_creation FROM items ORDER BY id")
        rows = cur.fetchall()
        cur.close()
        conn.close()
        
        items = []
        for row in rows:
            items.append({
                "id": row[0],
                "nom": row[1],
                "description": row[2],
                "date_creation": str(row[3])
            })
        
        return jsonify({"items": items, "count": len(items)})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/items', methods=['POST'])
def add_item():
    """Route POST /items - Ajoute un nouvel item dans la DB"""
    try:
        data = request.get_json()
        
        # Vérif les données 
        if not data or 'nom' not in data:
            return jsonify({"error": "Le champ 'nom' est requis"}), 400
        
        nom = data['nom']
        description = data.get('description', '')
        
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO items (nom, description) VALUES (%s, %s) RETURNING id, nom, description, date_creation",
            (nom, description)
        )
        row = cur.fetchone()
        conn.commit()
        cur.close()
        conn.close()
        
        new_item = {
            "id": row[0],
            "nom": row[1],
            "description": row[2],
            "date_creation": str(row[3])
        }
        
        return jsonify({"message": "Item créé avec succès!", "item": new_item}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/items/<int:item_id>', methods=['DELETE'])
def delete_item(item_id):
    """Route DELETE /items/<id> - Supprime un item de la DB"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Vérifier si l'item existe
        cur.execute("SELECT id FROM items WHERE id = %s", (item_id,))
        if cur.fetchone() is None:
            cur.close()
            conn.close()
            return jsonify({"error": f"Item {item_id} non trouvé"}), 404
        
        # Supprimer l'item
        cur.execute("DELETE FROM items WHERE id = %s", (item_id,))
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({"message": f"Item {item_id} supprimé avec succès!"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/')
def home():
    """Page d'accueil de l'API"""
    return jsonify({
        "message": "Bienvenue sur mon API TD Docker!",
        "routes": [
            "GET /status - Vérifier le status de l'API",
            "GET /items - Liste tous les items",
            "POST /items - Créer un item (JSON: {nom, description})",
            "DELETE /items/<id> - Supprimer un item"
        ]
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=HTTP_PORT, debug=False)
