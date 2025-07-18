#!/bin/bash

echo "🔍 ANALYSE SÉMANTIQUE DES FICHIERS INUTILISÉS - $(date)"
echo "======================================================="

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
TEMP_DIR=$(mktemp -d)
SRC_DIR="src"
PUBLIC_DIR="public"
UNUSED_FILES=()
TOTAL_FILES=0
REFERENCED_FILES=()

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Vérifications préliminaires
if [ ! -f "package.json" ]; then
    print_error "Aucun fichier package.json trouvé. Êtes-vous dans le bon répertoire ?"
    exit 1
fi

if [ ! -d "$SRC_DIR" ]; then
    print_error "Répertoire src/ non trouvé"
    exit 1
fi

print_success "Début de l'analyse sémantique"

# 1. Lister tous les fichiers source
print_section "INVENTAIRE DES FICHIERS SOURCE"

# Créer la liste de tous les fichiers
find "$SRC_DIR" -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.vue" -o -name "*.css" -o -name "*.scss" -o -name "*.less" \) > "$TEMP_DIR/all_files.txt"

# Exclure les fichiers de configuration et tests
grep -v -E "\.(test|spec|stories)\.(ts|tsx|js|jsx)$" "$TEMP_DIR/all_files.txt" > "$TEMP_DIR/source_files.txt"
grep -v -E "\.d\.ts$" "$TEMP_DIR/source_files.txt" > "$TEMP_DIR/filtered_files.txt"

TOTAL_FILES=$(wc -l < "$TEMP_DIR/filtered_files.txt")
print_info "Fichiers source trouvés: $TOTAL_FILES"

# 2. Analyser les imports et références
print_section "ANALYSE DES IMPORTS ET RÉFÉRENCES"

# Créer un fichier de tous les imports/exports
{
    # Imports ES6/TypeScript
    grep -r -h --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
         -E "^import .* from ['\"]" "$SRC_DIR" 2>/dev/null | \
         sed -E "s/.*from ['\"]([^'\"]*)['\"].*/\1/"
    
    # Dynamic imports
    grep -r -h --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
         -E "import\(['\"]" "$SRC_DIR" 2>/dev/null | \
         sed -E "s/.*import\(['\"]([^'\"]*)['\"].*/\1/"
    
    # Require statements
    grep -r -h --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
         -E "require\(['\"]" "$SRC_DIR" 2>/dev/null | \
         sed -E "s/.*require\(['\"]([^'\"]*)['\"].*/\1/"
} | grep -E "^[\./]" | sed 's/\.\///g' > "$TEMP_DIR/imports.txt"

# 3. Rechercher les références dans les fichiers
print_section "RECHERCHE DES RÉFÉRENCES"

# Fonction pour normaliser les chemins d'import
normalize_import() {
    local import_path="$1"
    local base_dir="$2"
    
    # Supprimer l'extension si présente
    import_path=$(echo "$import_path" | sed 's/\.(ts|tsx|js|jsx)$//')
    
    # Gérer les imports relatifs
    if [[ "$import_path" == ./* ]]; then
        import_path="${import_path#./}"
    fi
    
    # Ajouter src/ si nécessaire
    if [[ ! "$import_path" == src/* ]]; then
        import_path="src/$import_path"
    fi
    
    echo "$import_path"
}

# Marquer les fichiers référencés
touch "$TEMP_DIR/referenced.txt"

# Points d'entrée toujours considérés comme utilisés
echo "src/main.tsx" >> "$TEMP_DIR/referenced.txt"
echo "src/App.tsx" >> "$TEMP_DIR/referenced.txt"
echo "src/index.css" >> "$TEMP_DIR/referenced.txt"

while IFS= read -r file; do
    # Analyser les imports dans ce fichier
    {
        grep -E "^import .* from ['\"]" "$file" 2>/dev/null | sed -E "s/.*from ['\"]([^'\"]*)['\"].*/\1/"
        grep -E "import\(['\"]" "$file" 2>/dev/null | sed -E "s/.*import\(['\"]([^'\"]*)['\"].*/\1/"
        grep -E "require\(['\"]" "$file" 2>/dev/null | sed -E "s/.*require\(['\"]([^'\"]*)['\"].*/\1/"
    } | while IFS= read -r import_line; do
        if [[ "$import_line" =~ ^[\./] ]]; then
            # Import relatif/local
            base_dir=$(dirname "$file")
            
            # Résoudre le chemin
            if [[ "$import_line" == ./* ]]; then
                resolved_path="$base_dir/${import_line#./}"
            elif [[ "$import_line" == ../* ]]; then
                resolved_path="$base_dir/$import_line"
            else
                resolved_path="$import_line"
            fi
            
            # Normaliser le chemin
            resolved_path=$(realpath -m "$resolved_path" 2>/dev/null || echo "$resolved_path")
            
            # Essayer différentes extensions
            for ext in "" ".ts" ".tsx" ".js" ".jsx" ".css" ".scss"; do
                test_path="${resolved_path}${ext}"
                if [ -f "$test_path" ]; then
                    echo "$test_path" >> "$TEMP_DIR/referenced.txt"
                    break
                fi
                
                # Essayer avec index
                test_path="${resolved_path}/index${ext}"
                if [ -f "$test_path" ]; then
                    echo "$test_path" >> "$TEMP_DIR/referenced.txt"
                    break
                fi
            done
        fi
    done
done < "$TEMP_DIR/filtered_files.txt"

# 4. Rechercher les références par nom de fichier (pour les assets, etc.)
print_section "RECHERCHE DES RÉFÉRENCES PAR NOM"

# Chercher les références aux fichiers dans le code
while IFS= read -r file; do
    filename=$(basename "$file")
    filename_no_ext=$(basename "$file" | sed 's/\.[^.]*$//')
    
    # Chercher les références dans tout le code
    if grep -r -q "$filename\|$filename_no_ext" "$SRC_DIR" 2>/dev/null; then
        echo "$file" >> "$TEMP_DIR/referenced.txt"
    fi
    
    # Chercher les imports par nom de composant/module
    if grep -r -q "from.*['\"].*$filename_no_ext['\"]" "$SRC_DIR" 2>/dev/null; then
        echo "$file" >> "$TEMP_DIR/referenced.txt"
    fi
done < "$TEMP_DIR/filtered_files.txt"

# 5. Analyser les fichiers publics utilisés
print_section "ANALYSE DES ASSETS PUBLICS"

if [ -d "$PUBLIC_DIR" ]; then
    find "$PUBLIC_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.svg" -o -name "*.ico" \) > "$TEMP_DIR/public_assets.txt"
    
    unused_assets=0
    total_assets=$(wc -l < "$TEMP_DIR/public_assets.txt")
    
    while IFS= read -r asset; do
        asset_name=$(basename "$asset")
        # Chercher les références dans le code et HTML
        if ! grep -r -q "$asset_name" "$SRC_DIR" . --include="*.html" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" --include="*.css" 2>/dev/null; then
            echo "$asset" >> "$TEMP_DIR/unused_assets.txt"
            unused_assets=$((unused_assets + 1))
        fi
    done < "$TEMP_DIR/public_assets.txt"
    
    print_info "Assets publics: $total_assets total, $unused_assets potentiellement inutilisés"
fi

# 6. Générer la liste des fichiers inutilisés
print_section "GÉNÉRATION DE LA LISTE DES FICHIERS INUTILISÉS"

# Supprimer les doublons et trier
sort "$TEMP_DIR/referenced.txt" | uniq > "$TEMP_DIR/referenced_unique.txt"

unused_count=0
while IFS= read -r file; do
    if ! grep -Fq "$file" "$TEMP_DIR/referenced_unique.txt"; then
        echo "$file" >> "$TEMP_DIR/unused_source.txt"
        unused_count=$((unused_count + 1))
    fi
done < "$TEMP_DIR/filtered_files.txt"

# 7. Afficher les résultats
print_section "RÉSULTATS DE L'ANALYSE"

echo "📊 Statistiques :"
echo "  - Fichiers source analysés: $TOTAL_FILES"
echo "  - Fichiers référencés: $(wc -l < "$TEMP_DIR/referenced_unique.txt" 2>/dev/null || echo "0")"
echo "  - Fichiers potentiellement inutilisés: $unused_count"

if [ -f "$TEMP_DIR/unused_assets.txt" ]; then
    assets_unused=$(wc -l < "$TEMP_DIR/unused_assets.txt" 2>/dev/null || echo "0")
    echo "  - Assets potentiellement inutilisés: $assets_unused"
fi

if [ $unused_count -gt 0 ]; then
    print_warning "Fichiers source potentiellement inutilisés :"
    if [ -f "$TEMP_DIR/unused_source.txt" ]; then
        while IFS= read -r file; do
            size=$(stat -c%s "$file" 2>/dev/null || echo "0")
            echo "  - $file ($size bytes)"
        done < "$TEMP_DIR/unused_source.txt" | head -20
        
        if [ $unused_count -gt 20 ]; then
            echo "  ... et $((unused_count - 20)) autres fichiers"
        fi
    fi
else
    print_success "Tous les fichiers source semblent être utilisés !"
fi

if [ -f "$TEMP_DIR/unused_assets.txt" ] && [ -s "$TEMP_DIR/unused_assets.txt" ]; then
    echo ""
    print_warning "Assets potentiellement inutilisés :"
    head -10 "$TEMP_DIR/unused_assets.txt" | while IFS= read -r file; do
        size=$(stat -c%s "$file" 2>/dev/null || echo "0")
        echo "  - $file ($size bytes)"
    done
fi

# 8. Générer un script de nettoyage optionnel
print_section "GÉNÉRATION DU SCRIPT DE NETTOYAGE"

if [ $unused_count -gt 0 ] || [ -f "$TEMP_DIR/unused_assets.txt" ]; then
    cat > "scripts/remove-unused-files.sh" << 'EOF'
#!/bin/bash

echo "🗑️  SUPPRESSION DES FICHIERS INUTILISÉS"
echo "======================================="
echo "⚠️  ATTENTION: Ce script va supprimer des fichiers !"
echo "💾 Assurez-vous d'avoir une sauvegarde avant de continuer."
echo ""

read -p "Voulez-vous continuer ? (tapez 'OUI' pour confirmer): " confirm
if [ "$confirm" != "OUI" ]; then
    echo "Opération annulée."
    exit 1
fi

# Créer une sauvegarde
backup_dir="unused-files-backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"

EOF

    if [ -f "$TEMP_DIR/unused_source.txt" ]; then
        echo "# Sauvegarder et supprimer les fichiers source inutilisés" >> "scripts/remove-unused-files.sh"
        while IFS= read -r file; do
            echo "cp \"$file\" \"$backup_dir/\" 2>/dev/null && rm \"$file\"" >> "scripts/remove-unused-files.sh"
        done < "$TEMP_DIR/unused_source.txt"
    fi
    
    if [ -f "$TEMP_DIR/unused_assets.txt" ]; then
        echo "# Sauvegarder et supprimer les assets inutilisés" >> "scripts/remove-unused-files.sh"
        while IFS= read -r file; do
            echo "cp \"$file\" \"$backup_dir/\" 2>/dev/null && rm \"$file\"" >> "scripts/remove-unused-files.sh"
        done < "$TEMP_DIR/unused_assets.txt"
    fi
    
    echo 'echo "✅ Fichiers supprimés et sauvegardés dans $backup_dir"' >> "scripts/remove-unused-files.sh"
    chmod +x "scripts/remove-unused-files.sh"
    
    print_success "Script de nettoyage généré: scripts/remove-unused-files.sh"
    print_warning "⚠️  Vérifiez manuellement la liste avant d'exécuter le script !"
fi

# 9. Recommandations finales
print_section "RECOMMANDATIONS"

echo "💡 Actions recommandées :"
echo "  1. Vérifiez manuellement les fichiers listés ci-dessus"
echo "  2. Certains fichiers peuvent être utilisés dynamiquement"
echo "  3. Testez votre application après suppression"
echo "  4. Utilisez un linter comme ESLint avec des règles pour les imports inutilisés"

if command -v npx >/dev/null 2>&1; then
    echo "  5. Considérez l'utilisation d'outils spécialisés :"
    echo "     - npx unimported (détection avancée)"
    echo "     - npx depcheck (dépendances inutilisées)"
fi

echo ""
echo "🏁 Analyse terminée - $(date)"

# Sauvegarder les résultats
if [ $unused_count -gt 0 ]; then
    cp "$TEMP_DIR/unused_source.txt" "unused-files-$(date +%Y%m%d).txt" 2>/dev/null
    echo "📄 Liste sauvegardée dans: unused-files-$(date +%Y%m%d).txt"
fi