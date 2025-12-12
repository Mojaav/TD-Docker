# TD Docker
## Démarrage Rapide

```bash
# Cloner le projet et se placer dedans
cd td-docker-app

# Démarrer l'application
docker compose up -d

# Accéder à l'application
# Frontend: http://localhost:8080
# API Status: http://localhost:8080/api/status
# API Items: http://localhost:8080/api/items
```

## Structure du Projet

```
td-docker-app/
├── api/           # API Flask (Python)
├── frontend/      # Interface web (HTML/CSS/JS + Nginx)
├── db/            # Scripts d'init PostgreSQL
├── docker-compose.yml
├── deploy.sh      # Script d'automatisation
└── RAPPORT.md     # Rapport de synthèse
```

## Commandes Utiles

```bash
# Voir les logs
docker compose logs -f

# Arrêter l'application
docker compose down

# Tout reconstruire
docker compose up -d --build

# Utiliser le script automatisé
./deploy.sh deploy   
./deploy.sh cleanup  
```

## Fonctionnalités

- API REST avec Flask (routes /status et /items)
- Base de données PostgreSQL avec données de test
- Frontend responsive qui interroge l'API
- Builds multi-étapes (images légères)
- Sécurité (utilisateur non-root, capacités réduites)
- Healthchecks sur tous les services
- Script d'automatisation complet
