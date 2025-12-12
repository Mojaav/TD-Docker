-- Script d'initialisation de la base de données
-- Ce fichier sera exécuté automatiquement au démarrage du conteneur PostgreSQL

-- Création de la table items
CREATE TABLE IF NOT EXISTS items (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    description TEXT,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insertion de données de test
INSERT INTO items (nom, description) VALUES 
    ('Premier item', 'Ceci est le premier item de test'),
    ('Deuxième item', 'Un autre item pour tester'),
    ('Tâche importante', 'Il faut rendre le TD Docker!'),
    ('Note de cours', 'Docker c''est super pratique'),
    ('Projet final', 'Application conteneurisée complète');

-- Message de confirmation
SELECT 'Base de données initialisée avec succès!' as message;
