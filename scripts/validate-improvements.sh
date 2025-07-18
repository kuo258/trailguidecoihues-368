#!/bin/bash

echo "✅ VALIDATION DES AMÉLIORATIONS - $(date)"
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

# Variables pour le scoring
total_tests=0
passed_tests=0

# Fonction de test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"  # 0 pour succès, 1 pour échec attendu
    
    total_tests=$((total_tests + 1))
    
    if eval "$test_command"; then
        actual_result=0
    else
        actual_result=1
    fi
    
    if [ "$actual_result" -eq "$expected_result" ]; then
        print_success "$test_name"
        passed_tests=$((passed_tests + 1))
        return 0
    else
        print_error "$test_name"
        return 1
    fi
}

# Vérifications préliminaires
if [ ! -f "package.json" ]; then
    print_error "Aucun fichier package.json trouvé. Êtes-vous dans le bon répertoire ?"
    exit 1
fi

print_success "Début de la validation"

# 1. Validation de la structure du projet
print_section "VALIDATION DE LA STRUCTURE DU PROJET"

run_test "package.json existe" "[ -f 'package.json' ]" 0
run_test "Répertoire src existe" "[ -d 'src' ]" 0
run_test "Répertoire node_modules existe" "[ -d 'node_modules' ]" 0

# 2. Validation des gestionnaires de paquets
print_section "VALIDATION DES GESTIONNAIRES DE PAQUETS"

lockfile_count=0
[ -f "package-lock.json" ] && lockfile_count=$((lockfile_count + 1))
[ -f "yarn.lock" ] && lockfile_count=$((lockfile_count + 1))
[ -f "pnpm-lock.yaml" ] && lockfile_count=$((lockfile_count + 1))
[ -f "bun.lockb" ] && lockfile_count=$((lockfile_count + 1))

if [ $lockfile_count -eq 1 ]; then
    print_success "Un seul fichier de lock présent"
    passed_tests=$((passed_tests + 1))
elif [ $lockfile_count -eq 0 ]; then
    print_warning "Aucun fichier de lock trouvé"
else
    print_warning "Plusieurs fichiers de lock présents ($lockfile_count)"
fi
total_tests=$((total_tests + 1))

# Identifier le gestionnaire principal
if [ -f "package-lock.json" ]; then
    primary_manager="npm"
    print_info "Gestionnaire principal: npm"
elif [ -f "yarn.lock" ]; then
    primary_manager="yarn"
    print_info "Gestionnaire principal: yarn"
elif [ -f "pnpm-lock.yaml" ]; then
    primary_manager="pnpm"
    print_info "Gestionnaire principal: pnpm"
elif [ -f "bun.lockb" ]; then
    primary_manager="bun"
    print_info "Gestionnaire principal: bun"
else
    primary_manager="unknown"
    print_warning "Gestionnaire principal non identifié"
fi

# 3. Validation du nettoyage des fichiers indésirables
print_section "VALIDATION DU NETTOYAGE"

# Test des fichiers temporaires
temp_files=$(find . -name "*.tmp" -o -name "*.temp" -o -name "*.bak" -o -name "*.backup" -o -name "*~" -o -name "*.orig" -o -name "*.rej" 2>/dev/null | wc -l)
run_test "Aucun fichier temporaire" "[ $temp_files -eq 0 ]" 0

# Test des fichiers système
system_files=$(find . -name ".DS_Store" -o -name "Thumbs.db" -o -name "desktop.ini" 2>/dev/null | wc -l)
run_test "Aucun fichier système indésirable" "[ $system_files -eq 0 ]" 0

# Test des répertoires de build (ils ne devraient pas exister après nettoyage)
run_test "Répertoire dist nettoyé" "[ ! -d 'dist' ]" 0
run_test "Répertoire build nettoyé" "[ ! -d 'build' ]" 0
run_test "Répertoire .vite nettoyé" "[ ! -d '.vite' ]" 0

# 4. Validation de la configuration
print_section "VALIDATION DE LA CONFIGURATION"

run_test "Fichier .gitignore présent" "[ -f '.gitignore' ]" 0

if [ -f ".gitignore" ]; then
    # Vérifier que .gitignore contient les entrées essentielles
    run_test ".gitignore contient node_modules" "grep -q 'node_modules' '.gitignore'" 0
    run_test ".gitignore contient .DS_Store" "grep -q 'DS_Store' '.gitignore'" 0
    run_test ".gitignore contient *.log" "grep -q '*.log' '.gitignore'" 0
fi

# 5. Validation des dépendances
print_section "VALIDATION DES DÉPENDANCES"

if command -v npm >/dev/null 2>&1; then
    print_info "Vérification de l'installation des dépendances..."
    
    # Test d'installation des dépendances
    if npm list --depth=0 >/dev/null 2>&1; then
        print_success "Toutes les dépendances sont installées"
        passed_tests=$((passed_tests + 1))
    else
        print_warning "Certaines dépendances semblent manquer"
    fi
    total_tests=$((total_tests + 1))
    
    # Test de sécurité
    print_info "Vérification des vulnérabilités de sécurité..."
    audit_result=$(npm audit --audit-level=high 2>/dev/null)
    if [ $? -eq 0 ]; then
        print_success "Aucune vulnérabilité critique détectée"
        passed_tests=$((passed_tests + 1))
    else
        high_vulns=$(echo "$audit_result" | grep -o "[0-9]\+ high" | head -1 | grep -o "[0-9]\+")
        critical_vulns=$(echo "$audit_result" | grep -o "[0-9]\+ critical" | head -1 | grep -o "[0-9]\+")
        
        if [ -n "$high_vulns" ] || [ -n "$critical_vulns" ]; then
            print_warning "Vulnérabilités détectées (high: ${high_vulns:-0}, critical: ${critical_vulns:-0})"
        else
            print_info "Audit de sécurité terminé"
        fi
    fi
    total_tests=$((total_tests + 1))
else
    print_warning "npm non disponible pour la validation"
fi

# 6. Tests de fonctionnement
print_section "TESTS DE FONCTIONNEMENT"

# Test de build (si script disponible)
if grep -q '"build"' package.json; then
    print_info "Test du processus de build..."
    if [ "$primary_manager" = "npm" ]; then
        build_cmd="npm run build"
    elif [ "$primary_manager" = "yarn" ]; then
        build_cmd="yarn build"
    elif [ "$primary_manager" = "pnpm" ]; then
        build_cmd="pnpm run build"
    elif [ "$primary_manager" = "bun" ]; then
        build_cmd="bun run build"
    else
        build_cmd="npm run build"
    fi
    
    if timeout 60 $build_cmd >/dev/null 2>&1; then
        print_success "Build réussie"
        passed_tests=$((passed_tests + 1))
        
        # Nettoyer après le test
        [ -d "dist" ] && rm -rf dist
        [ -d "build" ] && rm -rf build
    else
        print_warning "Échec du build ou timeout (60s)"
    fi
    total_tests=$((total_tests + 1))
fi

# Test de linting (si script disponible)
if grep -q '"lint"' package.json; then
    print_info "Test du linting..."
    if [ "$primary_manager" = "npm" ]; then
        lint_cmd="npm run lint"
    elif [ "$primary_manager" = "yarn" ]; then
        lint_cmd="yarn lint"
    elif [ "$primary_manager" = "pnpm" ]; then
        lint_cmd="pnpm run lint"
    elif [ "$primary_manager" = "bun" ]; then
        lint_cmd="bun run lint"
    else
        lint_cmd="npm run lint"
    fi
    
    if timeout 30 $lint_cmd >/dev/null 2>&1; then
        print_success "Linting réussi"
        passed_tests=$((passed_tests + 1))
    else
        print_warning "Échec du linting ou timeout (30s)"
    fi
    total_tests=$((total_tests + 1))
fi

# 7. Analyse de performance
print_section "ANALYSE DE PERFORMANCE"

# Taille totale du projet
project_size=$(du -sh . 2>/dev/null | cut -f1)
print_info "Taille totale du projet: $project_size"

# Taille des node_modules
if [ -d "node_modules" ]; then
    node_modules_size=$(du -sh node_modules 2>/dev/null | cut -f1)
    print_info "Taille des node_modules: $node_modules_size"
fi

# Nombre de fichiers
file_count=$(find . -type f | wc -l)
print_info "Nombre total de fichiers: $file_count"

# 8. Recommandations
print_section "RECOMMANDATIONS"

recommendations=()

# Vérifier la taille des node_modules
if [ -d "node_modules" ]; then
    node_modules_mb=$(du -sm node_modules 2>/dev/null | cut -f1)
    if [ "$node_modules_mb" -gt 500 ]; then
        recommendations+=("Considérer l'utilisation de pnpm pour réduire la taille des dépendances")
    fi
fi

# Vérifier les uploads
if [ -d "public/lovable-uploads" ]; then
    uploads_count=$(find public/lovable-uploads -type f 2>/dev/null | wc -l)
    if [ "$uploads_count" -gt 20 ]; then
        recommendations+=("Nettoyer les fichiers uploadés anciens dans public/lovable-uploads/")
    fi
fi

# Vérifier les vulnérabilités
if command -v npm >/dev/null 2>&1; then
    vuln_count=$(npm audit --json 2>/dev/null | grep -o '"vulnerabilities":[0-9]*' | grep -o '[0-9]*' || echo "0")
    if [ "$vuln_count" -gt 0 ]; then
        recommendations+=("Exécuter 'npm audit fix' pour corriger les vulnérabilités")
    fi
fi

if [ ${#recommendations[@]} -gt 0 ]; then
    echo "💡 Recommandations :"
    for rec in "${recommendations[@]}"; do
        echo "  - $rec"
    done
else
    print_success "Aucune recommandation supplémentaire"
fi

# 9. Score final
print_section "SCORE FINAL"

percentage=$((passed_tests * 100 / total_tests))

echo "📊 Résultats des tests:"
echo "  - Tests réussis: $passed_tests/$total_tests"
echo "  - Score: $percentage%"

if [ $percentage -ge 90 ]; then
    print_success "Excellent ! Projet très bien optimisé"
    echo "🏆 Votre projet est dans un état optimal"
elif [ $percentage -ge 75 ]; then
    print_success "Très bien ! Quelques améliorations mineures possibles"
    echo "👍 Votre projet est bien optimisé"
elif [ $percentage -ge 60 ]; then
    print_warning "Bien, mais des améliorations sont recommandées"
    echo "⚠️  Consultez les recommandations ci-dessus"
else
    print_error "Des améliorations importantes sont nécessaires"
    echo "❌ Relancez le script de nettoyage ou consultez la documentation"
fi

# 10. Prochaines étapes
print_section "PROCHAINES ÉTAPES"

echo "🔄 Maintenance recommandée :"
echo "  1. Exécuter l'analyse mensuelle: ./scripts/analyze-unused-files.sh"
echo "  2. Nettoyer régulièrement: ./scripts/cleanup-project.sh"
echo "  3. Valider après changements: ./scripts/validate-improvements.sh"
echo "  4. Mettre à jour les dépendances: npm update (ou équivalent)"
echo "  5. Vérifier la sécurité: npm audit"

echo ""
echo "🏁 Validation terminée - $(date)"

# Code de sortie basé sur le score
if [ $percentage -ge 75 ]; then
    exit 0
else
    exit 1
fi