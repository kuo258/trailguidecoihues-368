#!/bin/bash

echo "🔍 ANALYSE COMPLÈTE DES FICHIERS INUTILISÉS"
echo "============================================"

echo "1. Test avec unimported:"
npx unimported | grep -E "(unimported files|unused dependencies)"

echo -e "\n2. Test avec ts-unused-exports:"
npx ts-unused-exports tsconfig.json --maxIssues=10 || echo "Aucun export inutilisé trouvé"

echo -e "\n3. Recherche de fichiers jamais importés:"
echo "Fichiers qui ne sont jamais importés par d'autres fichiers:"
find src -name "*.ts" -o -name "*.tsx" | while read file; do
    basename_file=$(basename "$file" | sed 's/\.[^.]*$//')
    # Chercher les imports de ce fichier
    if ! grep -r "from.*$basename_file\|import.*$basename_file" src/ --exclude="$file" >/dev/null 2>&1; then
        # Vérifier si c'est un point d'entrée
        if [[ ! "$file" =~ (main\.tsx|App\.tsx|index\.) ]]; then
            echo "  - $file"
        fi
    fi
done | head -20

echo -e "\n4. Analyse des exports non utilisés:"
echo "Fichiers qui exportent mais ne sont pas importés:"
grep -r "^export" src/ --include="*.ts" --include="*.tsx" | cut -d: -f1 | sort | uniq | while read file; do
    basename_file=$(basename "$file" | sed 's/\.[^.]*$//')
    if ! grep -r "from.*$basename_file\|import.*$basename_file" src/ --exclude="$file" >/dev/null 2>&1; then
        if [[ ! "$file" =~ (main\.tsx|App\.tsx|index\.) ]]; then
            echo "  - $file"
        fi
    fi
done | head -10

echo -e "\n5. Vérification des imports circulaires ou isolés:"
echo "Groupes de fichiers qui s'importent uniquement entre eux:"
# Cette analyse est plus complexe, on se contente d'une vérification simple
find src -name "*.tsx" -path "*/ai/*" | head -5 | while read file; do
    echo "Fichier: $file"
    echo "  Importé par (hors répertoire ai):"
    grep -r "$(basename "$file" .tsx)" src/ --include="*.tsx" --include="*.ts" | grep -v "/ai/" | head -2 || echo "    -> Aucune référence externe!"
done

echo -e "\n6. Résumé des outils d'analyse:"
echo "- unimported: $(npx unimported | grep "unimported files" | grep -o "[0-9]\+")"
echo "- ts-unused-exports: $(npx ts-unused-exports tsconfig.json --maxIssues=1000 | wc -l) issues"
echo "- Fichiers dans src/: $(find src -type f | wc -l)"
echo "- Fichiers TS/TSX: $(find src -name "*.ts" -o -name "*.tsx" | wc -l)"

echo -e "\n7. Suggestion pour Bolt.new:"
echo "Si Bolt.new montre 154 fichiers inutilisés, cela pourrait être:"
echo "  - Une analyse avec des paramètres différents"
echo "  - Une version différente d'unimported" 
echo "  - Une analyse incluant d'autres critères (tests, types, etc.)"
echo "  - Un cache non rafraîchi"

echo -e "\n8. Pour reproduire exactement Bolt.new:"
echo "Essayez ces commandes dans le terminal de Bolt.new:"
echo "  npx unimported --version"
echo "  npx unimported"
echo "  ls -la .unimportedrc* 2>/dev/null"

echo -e "\nAnalyse terminée!"