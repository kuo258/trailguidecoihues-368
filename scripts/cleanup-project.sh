#!/bin/bash

echo "🧹 NETTOYAGE AUTOMATIQUE DU PROJET - $(date)"
echo "================================================"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonctions utilitaires
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

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Configuration
BACKUP_DIR="cleanup-backup-$(date +%Y%m%d_%H%M%S)"
DRY_RUN=false
INTERACTIVE=true

# Options de ligne de commande
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --auto)
            INTERACTIVE=false
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --dry-run    Affiche ce qui serait fait sans rien supprimer"
            echo "  --auto       Mode automatique sans confirmation"
            echo "  --help       Affiche cette aide"
            exit 0
            ;;
        *)
            echo "Option inconnue: $1"
            exit 1
            ;;
    esac
done

# Vérifications préliminaires
if [ ! -f "package.json" ]; then
    print_error "Aucun fichier package.json trouvé. Êtes-vous dans le bon répertoire ?"
    exit 1
fi

if [ "$DRY_RUN" = true ]; then
    print_info "MODE DRY-RUN ACTIVÉ - Aucun fichier ne sera supprimé"
fi

# Création du répertoire de sauvegarde
create_backup_dir() {
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$BACKUP_DIR"
        print_success "Répertoire de sauvegarde créé : $BACKUP_DIR"
    fi
}

# Fonction de sauvegarde
backup_file() {
    local file="$1"
    if [ "$DRY_RUN" = false ] && [ -e "$file" ]; then
        local backup_path="$BACKUP_DIR/$(dirname "$file")"
        mkdir -p "$backup_path"
        cp -r "$file" "$backup_path/"
        echo "  💾 Sauvegardé: $file"
    fi
}

# Fonction de suppression sécurisée
safe_remove() {
    local target="$1"
    local description="$2"
    
    if [ -e "$target" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "  🗑️  SERAIT SUPPRIMÉ: $target ($description)"
        else
            backup_file "$target"
            rm -rf "$target"
            print_success "Supprimé: $target ($description)"
        fi
        return 0
    fi
    return 1
}

# Demande de confirmation
confirm_action() {
    local message="$1"
    if [ "$INTERACTIVE" = true ] && [ "$DRY_RUN" = false ]; then
        echo -e "${YELLOW}$message${NC}"
        read -p "Continuer ? (O/n): " -r
        if [[ ! $REPLY =~ ^[Oo]$ ]] && [[ ! -z $REPLY ]]; then
            return 1
        fi
    fi
    return 0
}

print_success "Projet Node.js détecté"

if [ "$DRY_RUN" = false ]; then
    create_backup_dir
fi

# 1. Nettoyage des gestionnaires de paquets multiples
print_section "NETTOYAGE DES GESTIONNAIRES DE PAQUETS"

# Déterminer le gestionnaire principal
primary_manager=""
if [ -f "package-lock.json" ]; then
    primary_manager="npm"
elif [ -f "yarn.lock" ]; then
    primary_manager="yarn"
elif [ -f "pnpm-lock.yaml" ]; then
    primary_manager="pnpm"
elif [ -f "bun.lockb" ]; then
    primary_manager="bun"
fi

if [ -n "$primary_manager" ]; then
    print_info "Gestionnaire principal détecté: $primary_manager"
    
    # Supprimer les autres fichiers de lock
    case $primary_manager in
        npm)
            safe_remove "yarn.lock" "Yarn lock file"
            safe_remove "pnpm-lock.yaml" "PNPM lock file"
            safe_remove "bun.lockb" "Bun lock file"
            ;;
        yarn)
            safe_remove "package-lock.json" "NPM lock file"
            safe_remove "pnpm-lock.yaml" "PNPM lock file"
            safe_remove "bun.lockb" "Bun lock file"
            ;;
        pnpm)
            safe_remove "package-lock.json" "NPM lock file"
            safe_remove "yarn.lock" "Yarn lock file"
            safe_remove "bun.lockb" "Bun lock file"
            ;;
        bun)
            safe_remove "package-lock.json" "NPM lock file"
            safe_remove "yarn.lock" "Yarn lock file"
            safe_remove "pnpm-lock.yaml" "PNPM lock file"
            ;;
    esac
else
    print_warning "Aucun gestionnaire de paquets détecté"
fi

# 2. Nettoyage des fichiers temporaires
print_section "NETTOYAGE DES FICHIERS TEMPORAIRES"

temp_patterns=(
    "*.tmp"
    "*.temp"
    "*.bak"
    "*.backup"
    "*~"
    "*.orig"
    "*.rej"
    "*.swp"
    "*.swo"
)

temp_found=false
for pattern in "${temp_patterns[@]}"; do
    while IFS= read -r -d '' file; do
        if [ ! "$temp_found" = true ]; then
            if confirm_action "Supprimer les fichiers temporaires ?"; then
                temp_found=true
            else
                break 2
            fi
        fi
        safe_remove "$file" "fichier temporaire"
    done < <(find . -name "$pattern" -type f -print0 2>/dev/null)
done

if [ "$temp_found" = false ]; then
    print_success "Aucun fichier temporaire trouvé"
fi

# 3. Nettoyage des fichiers système
print_section "NETTOYAGE DES FICHIERS SYSTÈME"

system_patterns=(
    ".DS_Store"
    "Thumbs.db"
    "desktop.ini"
    "._*"
)

system_found=false
for pattern in "${system_patterns[@]}"; do
    while IFS= read -r -d '' file; do
        if [ ! "$system_found" = true ]; then
            if confirm_action "Supprimer les fichiers système ?"; then
                system_found=true
            else
                break 2
            fi
        fi
        safe_remove "$file" "fichier système"
    done < <(find . -name "$pattern" -type f -print0 2>/dev/null)
done

if [ "$system_found" = false ]; then
    print_success "Aucun fichier système indésirable trouvé"
fi

# 4. Nettoyage des répertoires de build
print_section "NETTOYAGE DES RÉPERTOIRES DE BUILD"

build_dirs=(
    "dist"
    "build"
    ".next"
    ".nuxt"
    ".vite"
    "coverage"
)

build_found=false
for dir in "${build_dirs[@]}"; do
    if [ -d "$dir" ]; then
        if [ ! "$build_found" = true ]; then
            size=$(du -sh "$dir" 2>/dev/null | cut -f1)
            if confirm_action "Supprimer les répertoires de build ? (Total: $size)"; then
                build_found=true
            else
                break
            fi
        fi
        safe_remove "$dir" "répertoire de build"
    fi
done

if [ "$build_found" = false ]; then
    print_success "Aucun répertoire de build trouvé"
fi

# 5. Nettoyage du cache
print_section "NETTOYAGE DU CACHE"

cache_dirs=(
    ".cache"
    ".parcel-cache"
    ".eslintcache"
    ".stylelintcache"
)

cache_found=false
for dir in "${cache_dirs[@]}"; do
    if [ -e "$dir" ]; then
        if [ ! "$cache_found" = true ]; then
            if confirm_action "Supprimer les fichiers de cache ?"; then
                cache_found=true
            else
                break
            fi
        fi
        safe_remove "$dir" "cache"
    fi
done

# Nettoyage des logs
logs=$(find . -name "*.log" -not -path "./node_modules/*" -type f 2>/dev/null)
if [ -n "$logs" ]; then
    if confirm_action "Supprimer les fichiers de log ?"; then
        echo "$logs" | while read -r file; do
            safe_remove "$file" "fichier de log"
        done
    fi
fi

if [ "$cache_found" = false ] && [ -z "$logs" ]; then
    print_success "Aucun cache ou log problématique trouvé"
fi

# 6. Optimisation des dépendances
print_section "OPTIMISATION DES DÉPENDANCES"

if command -v npm >/dev/null 2>&1 && [ "$DRY_RUN" = false ]; then
    if confirm_action "Exécuter npm audit fix pour corriger les vulnérabilités ?"; then
        print_info "Correction des vulnérabilités..."
        npm audit fix 2>/dev/null || true
        print_success "Audit de sécurité terminé"
    fi
    
    if confirm_action "Nettoyer le cache npm ?"; then
        print_info "Nettoyage du cache npm..."
        npm cache clean --force 2>/dev/null || true
        print_success "Cache npm nettoyé"
    fi
fi

# 7. Création/mise à jour du .gitignore
print_section "VÉRIFICATION DU .GITIGNORE"

if [ ! -f ".gitignore" ]; then
    if confirm_action "Créer un fichier .gitignore ?"; then
        if [ "$DRY_RUN" = false ]; then
            cat > .gitignore << 'EOF'
# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.pnpm-debug.log*

# Build outputs
dist/
build/
.vite/
.next/
.nuxt/
.output/

# Environment variables
.env.local
.env.development.local
.env.test.local
.env.production.local

# Cache directories
.cache/
.parcel-cache/
.eslintcache
.stylelintcache

# OS generated files
.DS_Store
Thumbs.db
desktop.ini

# Editor files
.vscode/
.idea/
*.swp
*.swo
*~

# Logs
*.log
logs/

# Temporary files
*.tmp
*.temp
*.bak
*.backup
*.orig
*.rej

# Coverage
coverage/

# Lock files (adjust based on your package manager)
# yarn.lock
# pnpm-lock.yaml
# bun.lockb
EOF
            print_success "Fichier .gitignore créé"
        else
            print_info "SERAIT CRÉÉ: .gitignore"
        fi
    fi
else
    print_success "Fichier .gitignore déjà présent"
fi

# 8. Résumé final
print_section "RÉSUMÉ DU NETTOYAGE"

if [ "$DRY_RUN" = false ]; then
    if [ -d "$BACKUP_DIR" ]; then
        backup_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
        print_info "Sauvegarde créée dans: $BACKUP_DIR ($backup_size)"
        echo "💡 Pour restaurer un fichier : cp $BACKUP_DIR/path/to/file ./path/to/file"
        echo "💡 Pour supprimer la sauvegarde : rm -rf $BACKUP_DIR"
    fi
    
    echo ""
    print_success "Nettoyage terminé avec succès !"
    echo "🔍 Exécutez './scripts/validate-improvements.sh' pour valider les améliorations"
else
    print_info "Simulation terminée. Utilisez le script sans --dry-run pour effectuer le nettoyage"
fi

echo ""
echo "🏁 Nettoyage terminé - $(date)"