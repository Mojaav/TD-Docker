# ========================================
# Dockerfile Multi-étapes pour le Frontend
# ========================================

# ÉTAPE 1: Préparation des fichiers
FROM node:20-alpine as builder

WORKDIR /app

# On copie les fichiers sources
COPY index.html .
COPY style.css .
COPY nginx.conf .

# ÉTAPE 2: Image de production avec Nginx
FROM nginx:alpine as production

# Métadonnées
LABEL maintainer="eleve@ecole.fr"
LABEL description="Frontend statique pour le TD Docker"
LABEL version="1.0"

# Supprimer la config par défaut de Nginx
RUN rm /etc/nginx/conf.d/default.conf

# Copier notre config Nginx personnalisée
COPY --from=builder /app/nginx.conf /etc/nginx/conf.d/default.conf

# Copier les fichiers statiques depuis l'étape builder
COPY --from=builder /app/index.html /usr/share/nginx/html/
COPY --from=builder /app/style.css /usr/share/nginx/html/

# Port exposé
EXPOSE 80

# Healthcheck pour vérifier que Nginx répond
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:80/ || exit 1

# Commande de démarrage
CMD ["nginx", "-g", "daemon off;"]
