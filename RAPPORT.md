#  Rapport de Synthèse - TD Docker
## Application Conteneurisée Générique
---

## 1.Architecture du Projet

### Vue d'ensemble
```
┌─────────────────────────────────────────────────────────────┐
│                    NAVIGATEUR (Port 8080)                    │
└─────────────────────────────┬───────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  FRONTEND (Nginx)                            │
│                  - Sert les fichiers HTML/CSS/JS            │
│                  - Proxy vers l'API (/api/)                 │
└─────────────────────────────┬───────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    API (Flask + Gunicorn)                   │
│                  - GET /status → "OK"                       │
│                  - GET /items → Liste des items             │
│                  - POST /items → Créer un item              │
│                  - DELETE /items/<id> → Supprimer un item   │
└─────────────────────────────┬───────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  BASE DE DONNÉES (PostgreSQL)               │
│                  - Table "items"                            │
│                  - Données persistées via volume            │
└─────────────────────────────────────────────────────────────┘
```

### Description des services

| Service | Technologie | Port | Rôle |
|---------|-------------|------|------|
| **db** | PostgreSQL 15 Alpine | 5432 (interne) | Stockage des données |
| **api** | Python Flask + Gunicorn | 5000 (interne) | API REST |
| **frontend** | Nginx Alpine | 8080 (exposé) | Interface utilisateur |

---

## 2.Commandes Clés

### Construction des images
```bash
# Construire toutes les images
docker compose build

# Construire une image spécifique
docker build -t td-docker-api:latest ./api
docker build -t td-docker-frontend:latest ./frontend
```

### Déploiement
```bash
# Démarrer tous les services
docker compose up -d

# Voir les logs
docker compose logs -f

# Vérifier le status
docker compose ps

# Arrêter tout
docker compose down
```

### Vérification de la configuration
```bash
# Valider le docker-compose.yml
docker compose config

# Voir la taille des images
docker images | grep td-docker
```

### Utilisation du script automatisé
```bash
# Déployer (build + test + deploy)
./deploy.sh deploy

# Tout faire (build + test + push + deploy)
./deploy.sh all

# Nettoyer
./deploy.sh cleanup
```

---

## 3.Bonnes Pratiques Suivies

### Construction des Images

| Pratique | Implémentation |
|----------|----------------|
| **Build multi-étapes** | ✅ Dockerfile API: étape builder + production |
| **Images légères** | ✅ Utilisation de `python:3.11-slim` et `nginx:alpine` |
| **.dockerignore** | ✅ Exclusion des fichiers inutiles (tests, docs, node_modules...) |
| **Variables d'env externalisées** | ✅ Toutes les configs passées via environment |

### Sécurité

| Pratique | Implémentation |
|----------|----------------|
| **Utilisateur non-root** | ✅ `USER apiuser` dans le Dockerfile API |
| **Capacités retirées** | ✅ `cap_drop: ALL` sur l'API uniquement |
| **no-new-privileges** | ✅ `security_opt: no-new-privileges:true` sur l'API |
| **Headers de sécurité** | ✅ X-Frame-Options, X-Content-Type-Options dans Nginx |

> Note: Les cap_drop sur PostgreSQL et Nginx causaient des erreurs de permissions, donc on les a retirés.

### Supervision

| Pratique | Implémentation |
|----------|----------------|
| **Healthchecks** | ✅ Tous les services ont un healthcheck |
| **Dépendances** | ✅ `depends_on: condition: service_healthy` |
| **Restart policy** | ✅ `restart: unless-stopped` |

---

## 4.Économies Réalisées avec les Builds Multi-étapes

### Comparaison des tailles d'images

| Image | Sans multi-étapes (estimé) | Avec multi-étapes |
|-------|---------------------------|-------------------|
| API Flask | ~900 MB (python:3.11) | ~150 MB (python:3.11-slim) |
| Frontend | ~140 MB (node:20) | ~40 MB (nginx:alpine) |


### Pourquoi c'est important?
- Téléchargement plus rapide
- Moins d'espace disque utilisé
- Déploiement plus rapide
- Moins de surface d'attaque (moins de packages)

---

## 5.Structure des Fichiers

```
td-docker-app/
├── api/
│   ├── app.py              # Code de l'API Flask
│   ├── requirements.txt    # Dépendances Python
│   ├── Dockerfile          # Build multi-étapes
│   └── .dockerignore       # Fichiers à exclure
├── frontend/
│   ├── index.html          # Page web statique
│   ├── style.css           # Feuille de style CSS
│   ├── nginx.conf          # Config Nginx
│   ├── Dockerfile          # Build multi-étapes
│   └── .dockerignore       # Fichiers à exclure
├── db/
│   └── init.sql            # Script d'initialisation BDD
├── docker-compose.yml      # Orchestration des services
├── deploy.sh               # Script d'automatisation
├── .env.example            # Exemple de variables d'env
└── RAPPORT.md              # Ce rapport
```

---

## 6.Difficultés Rencontrées

### Problèmes résolus
1. **Ordre de démarrage des services**: Résolu avec `depends_on` et `condition: service_healthy`
2. **Connexion API → DB**: Il faut attendre que PostgreSQL soit vraiment prêt (healthcheck)
3. **CORS Frontend → API**: Résolu avec le proxy Nginx `/api/`
4. **Permissions utilisateur non-root**: Nécessite de bien configurer les permissions des fichiers

### Conseils pour les autres élèves
- Toujours tester avec `docker compose config` avant de lancer
- Utiliser `docker compose logs -f` pour débugger
- Les healthchecks sont super importants pour l'ordre de démarrage!

---

## 7.Améliorations Possibles

### Court terme
- [] Ajouter des tests unitaires pour l'API (pytest)
- [x] Ajouter un endpoint POST /items pour créer des items
- [x] Ajouter un endpoint DELETE /items/<id> pour supprimer des items
- [ ] Mettre en place des métriques Prometheus

### Moyen terme
- [ ] Pipeline CI/CD avec GitHub Actions
- [ ] Scan de sécurité des images (Trivy)
- [ ] Signature des images avec Cosign

### Long terme
- [ ] Déploiement sur Kubernetes
- [ ] Mise en place d'un reverse proxy avec Let's Encrypt (HTTPS)
- [ ] Scaling horizontal avec plusieurs replicas de l'API

---

## 8.Conclusion

Ce TD m'a permis de comprendre:
- Comment créer des images Docker optimisées
- L'importance des bonnes pratiques de sécurité
- Comment orchestrer plusieurs services avec Docker Compose
- L'automatisation du déploiement

**L'application fonctionne et est accessible sur http://localhost:8080** 🎉

---
