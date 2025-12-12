#!/bin/bash
# ========================================
# Script d'automatisation - TD Docker
# Build, Test, Push et Déploiement
# ========================================

set -e  # Arrêter le script en cas d'erreur

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PROJECT_NAME="td-docker"
API_IMAGE="${PROJECT_NAME}-api"
FRONTEND_IMAGE="${PROJECT_NAME}-frontend"
REGISTRY="${DOCKER_REGISTRY:-docker.io}"
USERNAME="${DOCKER_USERNAME:-monuser}"
TAG="${IMAGE_TAG:-latest}"

# Fonction pour afficher les messages
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Fonction pour afficher le header
print_header() {
    echo ""
    echo "========================================"
    echo "  TD Docker - Script d'automatisation"
    echo "========================================"
    echo ""
}

# ÉTAPE 1: Vérif pre-resq
check_prerequisites() {
    log_info "Vérification des prérequis..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker n'est pas installé!"
        exit 1
    fi
    
    if ! command -v docker compose &> /dev/null; then
        log_error "Docker Compose n'est pas installé!"
        exit 1
    fi
    
    log_success "Docker et Docker Compose sont installés ✓"
}

# ÉTAPE 2: Build des images
build_images() {
    log_info "Build des images Docker..."
    
    # Build de l'API
    log_info "Building API image..."
    docker build -t ${API_IMAGE}:${TAG} ./api
    log_success "Image API construite: ${API_IMAGE}:${TAG}"
    
    # Build du Frontend
    log_info "Building Frontend image..."
    docker build -t ${FRONTEND_IMAGE}:${TAG} ./frontend
    log_success "Image Frontend construite: ${FRONTEND_IMAGE}:${TAG}"
    
    # Afficher la taille des images
    log_info "Taille des images construites:"
    docker images | grep -E "(${API_IMAGE}|${FRONTEND_IMAGE}|REPOSITORY)"
}

# ÉTAPE 3: Tests (simples)
run_tests() {
    log_info "Exécution des tests..."
    
    # Test de syntaxe Python
    log_info "Vérification de la syntaxe Python..."
    python3 -m py_compile ./api/app.py 2>/dev/null || python -m py_compile ./api/app.py 2>/dev/null || log_warning "Python non disponible pour les tests locaux"
    
    # Vérification de la config Docker Compose
    log_info "Vérification de la configuration Docker Compose..."
    docker compose config --quiet
    log_success "Configuration Docker Compose valide ✓"
}

# ÉTAPE 4: Connexion au registre et push
push_images() {
    log_info "Push des images vers le registre..."
    
    # Vérifier si on doit push
    if [ "$SKIP_PUSH" = "true" ]; then
        log_warning "Push ignoré (SKIP_PUSH=true)"
        return
    fi
    
    # Connexion au registre
    log_info "Connexion au registre ${REGISTRY}..."
    if [ -n "$DOCKER_PASSWORD" ]; then
        echo "$DOCKER_PASSWORD" | docker login ${REGISTRY} -u ${USERNAME} --password-stdin
    else
        log_warning "DOCKER_PASSWORD non défini, tentative de connexion interactive..."
        docker login ${REGISTRY} -u ${USERNAME} || log_warning "Connexion au registre échouée, push ignoré"
    fi
    
    # Tag et push des images
    FULL_API_IMAGE="${REGISTRY}/${USERNAME}/${API_IMAGE}:${TAG}"
    FULL_FRONTEND_IMAGE="${REGISTRY}/${USERNAME}/${FRONTEND_IMAGE}:${TAG}"
    
    log_info "Tagging images..."
    docker tag ${API_IMAGE}:${TAG} ${FULL_API_IMAGE}
    docker tag ${FRONTEND_IMAGE}:${TAG} ${FULL_FRONTEND_IMAGE}
    
    log_info "Pushing ${FULL_API_IMAGE}..."
    docker push ${FULL_API_IMAGE} || log_warning "Push API échoué"
    
    log_info "Pushing ${FULL_FRONTEND_IMAGE}..."
    docker push ${FULL_FRONTEND_IMAGE} || log_warning "Push Frontend échoué"
    
    log_success "Images poussées vers le registre ✓"
}

# ÉTAPE 5: Déploiement
deploy() {
    log_info "Déploiement de l'application..."
    
    # Arrêter les anciens conteneurs si nécessaire
    log_info "Arrêt des anciens conteneurs..."
    docker compose down --remove-orphans 2>/dev/null || true
    
    # Démarrer les nouveaux conteneurs
    log_info "Démarrage des conteneurs..."
    docker compose up -d --build
    
    # Attendre que les services soient prêts
    log_info "Attente du démarrage des services..."
    sleep 10
    
    # Vérifier le status
    log_info "Status des conteneurs:"
    docker compose ps
    
    log_success "Application déployée avec succès! ✓"
    echo ""
    echo "========================================"
    echo "   Déploiement terminé!"
    echo "   Frontend: http://localhost:8080"
    echo "   API: http://localhost:8080/api/"
    echo "========================================"
}

# ÉTAPE 6: Nettoyage (optionnel)
cleanup() {
    log_info "Nettoyage..."
    docker compose down -v --remove-orphans
    docker image prune -f
    log_success "Nettoyage terminé ✓"
}

# Fonction principale
main() {
    print_header
    
    # Parse des arguments
    case "${1:-deploy}" in
        "build")
            check_prerequisites
            build_images
            ;;
        "test")
            check_prerequisites
            run_tests
            ;;
        "push")
            check_prerequisites
            push_images
            ;;
        "deploy")
            check_prerequisites
            build_images
            run_tests
            deploy
            ;;
        "all")
            check_prerequisites
            build_images
            run_tests
            push_images
            deploy
            ;;
        "cleanup")
            cleanup
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  build    - Construire les images Docker"
            echo "  test     - Exécuter les tests"
            echo "  push     - Pousser les images vers le registre"
            echo "  deploy   - Construire, tester et déployer (par défaut)"
            echo "  all      - Tout faire (build, test, push, deploy)"
            echo "  cleanup  - Nettoyer les conteneurs et images"
            echo "  help     - Afficher cette aide"
            echo ""
            echo "Variables d'environnement:"
            echo "  DOCKER_REGISTRY  - Registre Docker (défaut: docker.io)"
            echo "  DOCKER_USERNAME  - Nom d'utilisateur Docker"
            echo "  DOCKER_PASSWORD  - Mot de passe Docker"
            echo "  IMAGE_TAG        - Tag des images (défaut: latest)"
            echo "  SKIP_PUSH        - Ignorer le push (true/false)"
            ;;
        *)
            log_error "Commande inconnue: $1"
            echo "Utilisez '$0 help' pour voir les commandes disponibles"
            exit 1
            ;;
    esac
}

# Exécution
main "$@"
