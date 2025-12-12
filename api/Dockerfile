# ========================================
# Dockerfile Multi-étapes pour l'API Flask
# ========================================

# ÉTAPE 1: Build
FROM python:3.11-slim as builder

WORKDIR /app

# On copie les reqs
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# ÉTAPE 2: Prod 
FROM python:3.11-slim as production

# meta imagedata
LABEL maintainer="matheo.chatelard@ecoles-epsi.net"
LABEL description="API Flask pour le TD Docker"
LABEL version="1.0"

# Création d'un user non-root (sécurité)
RUN groupadd -r apiuser && useradd -r -g apiuser apiuser

WORKDIR /app

# On copie des deps
COPY --from=builder /root/.local /home/apiuser/.local

# On copie le code de l'app
COPY app.py .

# On check que l'user peut accéder aux packages
ENV PATH=/home/apiuser/.local/bin:$PATH

# Variables d'environnement par défaut (peuvent être surchargées)
ENV DB_HOST=db
ENV DB_PORT=5432
ENV DB_USER=postgres
ENV DB_PASSWORD=password
ENV DB_NAME=mydb
ENV HTTP_PORT=5000

# On change vers l'utilisateur non-root
USER apiuser

# Port exposé
EXPOSE 5000

# Healthcheck pour vérifier que l'API répond
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/status')" || exit 1

# Commande de démarrage avec Gunicorn (serveur de production)
CMD ["python", "-m", "gunicorn", "-b", "0.0.0.0:5000", "app:app"]
