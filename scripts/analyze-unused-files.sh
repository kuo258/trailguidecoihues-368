#!/bin/bash

echo "🔍 ANALYSE DES FICHIERS INUTILISÉS - $(date)"
echo "================================================"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les résultats
print_section() {
    echo -e "\n${BLUE}📋 $1${NC}"
    echo "----------------------------------------"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Vérification que nous sommes dans un projet Node.js
if [ ! -f "package.json" ]; then
    print_error "Aucun fichier package.json trouvé. Êtes-vous dans le bon répertoire ?"
    exit 1
fi

print_success "Projet Node.js détecté"

# 1. Analyse des gestionnaires de paquets multiples
print_section "GESTIONNAIRES DE PAQUETS"
lockfiles=()
[ -f "package-lock.json" ] && lockfiles+=("npm (package-lock.json)")
[ -f "yarn.lock" ] && lockfiles+=("yarn (yarn.lock)")
[ -f "pnpm-lock.yaml" ] && lockfiles+=("pnpm (pnpm-lock.yaml)")
[ -f "bun.lockb" ] && lockfiles+=("bun (bun.lockb)")

if [ ${#lockfiles[@]} -gt 1 ]; then
    print_warning "Multiples gestionnaires de paquets détectés :"
    for lockfile in "${lockfiles[@]}"; do
        echo "  - $lockfile"
    done
    echo "🔧 Recommandation: Utiliser un seul gestionnaire de paquets"
else
    print_success "Un seul gestionnaire de paquets utilisé: ${lockfiles[0]}"
fi

# 2. Fichiers de sauvegarde et temporaires
print_section "FICHIERS TEMPORAIRES ET SAUVEGARDES"
temp_files=$(find . -name "*.tmp" -o -name "*.temp" -o -name "*.bak" -o -name "*.backup" -o -name "*~" -o -name "*.orig" -o -name "*.rej" 2>/dev/null)
if [ -n "$temp_files" ]; then
    print_warning "Fichiers temporaires trouvés :"
    echo "$temp_files" | while read file; do
        echo "  - $file ($(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0") bytes)"
    done
else
    print_success "Aucun fichier temporaire trouvé"
fi

# 3. Fichiers système
print_section "FICHIERS SYSTÈME"
system_files=$(find . -name ".DS_Store" -o -name "Thumbs.db" -o -name "desktop.ini" 2>/dev/null)
if [ -n "$system_files" ]; then
    print_warning "Fichiers système trouvés :"
    echo "$system_files" | while read file; do
        echo "  - $file"
    done
else
    print_success "Aucun fichier système indésirable trouvé"
fi

# 4. Répertoires de build
print_section "RÉPERTOIRES DE BUILD"
build_dirs=()
[ -d "dist" ] && build_dirs+=("dist")
[ -d "build" ] && build_dirs+=("build")
[ -d ".next" ] && build_dirs+=(".next")
[ -d ".nuxt" ] && build_dirs+=(".nuxt")
[ -d ".vite" ] && build_dirs+=(".vite")
[ -d "coverage" ] && build_dirs+=("coverage")

if [ ${#build_dirs[@]} -gt 0 ]; then
    print_warning "Répertoires de build trouvés :"
    for dir in "${build_dirs[@]}"; do
        size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        echo "  - $dir ($size)"
    done
    echo "💡 Ces répertoires peuvent être supprimés et régénérés"
else
    print_success "Aucun répertoire de build trouvé"
fi

# 5. Cache et logs
print_section "CACHE ET LOGS"
cache_items=()
[ -d ".cache" ] && cache_items+=(".cache")
[ -d ".parcel-cache" ] && cache_items+=(".parcel-cache")
[ -d "node_modules/.cache" ] && cache_items+=("node_modules/.cache")
logs=$(find . -name "*.log" -not -path "./node_modules/*" 2>/dev/null)

if [ ${#cache_items[@]} -gt 0 ] || [ -n "$logs" ]; then
    if [ ${#cache_items[@]} -gt 0 ]; then
        print_warning "Répertoires de cache trouvés :"
        for item in "${cache_items[@]}"; do
            size=$(du -sh "$item" 2>/dev/null | cut -f1)
            echo "  - $item ($size)"
        done
    fi
    if [ -n "$logs" ]; then
        print_warning "Fichiers de log trouvés :"
        echo "$logs" | while read file; do
            size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
            echo "  - $file ($size bytes)"
        done
    fi
else
    print_success "Aucun cache ou log problématique trouvé"
fi

# 6. Analyse des dépendances (si npm/yarn disponible)
print_section "ANALYSE DES DÉPENDANCES"
if command -v npm >/dev/null 2>&1; then
    echo "🔍 Vérification des vulnérabilités de sécurité..."
    npm audit --audit-level=moderate 2>/dev/null | head -20
    echo ""
    
    echo "🔍 Recherche de paquets obsolètes..."
    npm outdated 2>/dev/null | head -10 || echo "Toutes les dépendances sont à jour"
else
    print_warning "npm non disponible pour l'analyse des dépendances"
fi

# 7. Taille totale du projet
print_section "ANALYSE DE TAILLE"
echo "📊 Taille des principaux répertoires :"
du -sh */ 2>/dev/null | sort -hr | head -10

# 8. Fichier .gitignore
print_section "VÉRIFICATION .GITIGNORE"
if [ -f ".gitignore" ]; then
    print_success "Fichier .gitignore présent"
    echo "📝 Entrées principales :"
    grep -E "^[^#]" .gitignore | head -10 | sed 's/^/  - /'
else
    print_warning "Aucun fichier .gitignore trouvé"
    echo "🔧 Recommandation: Créer un fichier .gitignore"
fi

# 9. Résumé et recommandations
print_section "RÉSUMÉ ET RECOMMANDATIONS"

total_temp=$(find . -name "*.tmp" -o -name "*.temp" -o -name "*.bak" -o -name "*.backup" -o -name "*~" 2>/dev/null | wc -l)
total_system=$(find . -name ".DS_Store" -o -name "Thumbs.db" 2>/dev/null | wc -l)
total_lockfiles=${#lockfiles[@]}

echo "📈 Statistiques :"
echo "  - Fichiers temporaires: $total_temp"
echo "  - Fichiers système: $total_system"
echo "  - Gestionnaires de paquets: $total_lockfiles"
echo "  - Répertoires de build: ${#build_dirs[@]}"

if [ $total_temp -gt 0 ] || [ $total_system -gt 0 ] || [ $total_lockfiles -gt 1 ]; then
    echo ""
    print_warning "Actions recommandées :"
    [ $total_temp -gt 0 ] && echo "  🧹 Supprimer les fichiers temporaires"
    [ $total_system -gt 0 ] && echo "  🧹 Supprimer les fichiers système"
    [ $total_lockfiles -gt 1 ] && echo "  🔧 Standardiser sur un gestionnaire de paquets"
    [ ${#build_dirs[@]} -gt 0 ] && echo "  🗂️  Nettoyer les répertoires de build"
    echo ""
    echo "💡 Exécutez './scripts/cleanup-project.sh' pour nettoyer automatiquement"
else
    print_success "Le projet est déjà bien optimisé !"
fi

echo ""
echo "🏁 Analyse terminée - $(date)"