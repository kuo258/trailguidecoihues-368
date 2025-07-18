#!/bin/bash

echo "🧹 NETTOYAGE DES 154 FICHIERS INUTILISÉS DÉTECTÉS - $(date)"
echo "============================================================"

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
BACKUP_DIR="unused-files-backup-$(date +%Y%m%d_%H%M%S)"
DRY_RUN=false
INTERACTIVE=true
CLEAN_DEPS=false

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
        --with-deps)
            CLEAN_DEPS=true
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --dry-run      Affiche ce qui serait fait sans rien supprimer"
            echo "  --auto         Mode automatique sans confirmation"
            echo "  --with-deps    Supprime aussi les dépendances inutilisées"
            echo "  --help         Affiche cette aide"
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

# Liste des fichiers inutilisés détectés par unimported
UNUSED_FILES=(
    "src/components/ai/AIAdvancedFeatures.tsx"
    "src/components/ai/AIRecommendationEngine.tsx"
    "src/components/ai/AutomaticSummarizer.tsx"
    "src/components/ai/ContextualSearchAssistant.tsx"
    "src/components/ai/ContextualSuggestions.tsx"
    "src/components/ai/IntelligentDocumentAnalyzer.tsx"
    "src/components/ai/PredictiveAnalysis.tsx"
    "src/components/ai/PredictiveAnalysisTab.tsx"
    "src/components/ai/PredictiveJuridicalAnalysis.tsx"
    "src/components/AILegalAssistant.tsx"
    "src/components/analysis/TrendsTab.tsx"
    "src/components/auth/LoginForm.tsx"
    "src/components/collaboration/AdvancedCollaborationTools.tsx"
    "src/components/collaboration/CollaborativeAnnotations.tsx"
    "src/components/collaboration/CollaborativeWorkflow.tsx"
    "src/components/collaboration/DomainForums.tsx"
    "src/components/collaboration/ExpertEcosystem.tsx"
    "src/components/common/ActionCard.tsx"
    "src/components/common/ActionHandler.tsx"
    "src/components/common/ConsolidatedSectionLayout.tsx"
    "src/components/common/EnhancedFieldsCounter.tsx"
    "src/components/common/EnhancedPerformanceDashboard.tsx"
    "src/components/common/EnhancedTabContent.tsx"
    "src/components/common/ErrorBoundary.tsx"
    "src/components/common/GlobalErrorBoundary.tsx"
    "src/components/common/Icons.tsx"
    "src/components/common/OptimizedErrorMessage.tsx"
    "src/components/common/OptimizedSectionLayout.tsx"
    "src/components/common/OptimizedSectionTemplate.tsx"
    "src/components/common/PerformanceDashboard.tsx"
    "src/components/common/SectionSearchBar.tsx"
    "src/components/common/SectionStats.tsx"
    "src/components/common/SectionTabs.tsx"
    "src/components/common/SectionTabsNavigation.tsx"
    "src/components/common/SecureCard.tsx"
    "src/components/common/SecureInput.tsx"
    "src/components/common/SecureWrapper.tsx"
    "src/components/common/StandardizedSectionTemplate.tsx"
    "src/components/common/UnifiedActionCards.tsx"
    "src/components/common/UnifiedAddButtonHandler.tsx"
    "src/components/common/UnifiedSearchInterface.tsx"
    "src/components/common/UnifiedSectionBase.tsx"
    "src/components/common/UnifiedSectionLayout.tsx"
    "src/components/common/UnifiedStatsGrid.tsx"
    "src/components/common/VirtualizedList.tsx"
    "src/components/configuration/integrations/BlockchainAuthSection.tsx"
    "src/components/configuration/integrations/ExportMultiFormatsSection.tsx"
    "src/components/configuration/integrations/GDPRComplianceSection.tsx"
    "src/components/configuration/integrations/InternationalStandardsSection.tsx"
    "src/components/dashboard/DashboardActions.tsx"
    "src/components/dashboard/DashboardCharts.tsx"
    "src/components/dashboard/DashboardStats.tsx"
    "src/components/forms/AddProcedureForm.tsx"
    "src/components/forms/ContactForm.tsx"
    "src/components/forms/DynamicFormRenderer.tsx"
    "src/components/forms/FormIntegrationHandler.tsx"
    "src/components/legal/LegalTextFormActions.tsx"
    "src/components/legal/LegalTextFormContainer.tsx"
    "src/components/legal/LegalTextFormContent.tsx"
    "src/components/legal/LegalTextFormMainInfo.tsx"
    "src/components/legal/LegalTextFormMetadata.tsx"
    "src/components/legal/LegalTextFormProvider.tsx"
    "src/components/legal/LegalTextsComparisonTab.tsx"
    "src/components/legal/LegalTextStep1Enhanced.tsx"
    "src/components/legal/LegalTextStep2Enhanced.tsx"
    "src/components/legal/LegalTextStep3Enhanced.tsx"
    "src/components/legal/LegalTextStep4Enhanced.tsx"
    "src/components/LegalTextSummaryModal.tsx"
    "src/components/modals/AIGenerationModal.tsx"
    "src/components/modals/AnalysisModal.tsx"
    "src/components/modals/common/ModalActions.tsx"
    "src/components/modals/common/ModalLoading.tsx"
    "src/components/modals/ComparisonModal.tsx"
    "src/components/modals/context/ModalProvider.tsx"
    "src/components/modals/core/AIModalGroup.tsx"
    "src/components/modals/core/BaseModalGroup.tsx"
    "src/components/modals/core/DataModalGroup.tsx"
    "src/components/modals/core/ManagementModalGroup.tsx"
    "src/components/modals/core/OptimizedModalGroup.tsx"
    "src/components/modals/core/SearchModalGroup.tsx"
    "src/components/modals/DocumentViewerModal.tsx"
    "src/components/modals/enhanced/EnhancedPDFViewerModal.tsx"
    "src/components/modals/enhanced/ExampleEnhancedModal.tsx"
    "src/components/modals/FilterModal.tsx"
    "src/components/modals/GeolocationSearchModal.tsx"
    "src/components/modals/PDFViewerModal.tsx"
    "src/components/modals/ProjectManagerModal.tsx"
    "src/components/modals/SessionManagementModal.tsx"
    "src/components/modals/TagManagerModal.tsx"
    "src/components/modals/TemplateManagerModal.tsx"
    "src/components/modals/types/modalTypes.ts"
    "src/components/modals/UnifiedModalSystem.tsx"
    "src/components/modals/WorkflowManagerModal.tsx"
    "src/components/modals/WorkflowModal.tsx"
    "src/components/procedure-form/Step1GeneralInfo.tsx"
    "src/components/procedure-form/Step2StepsConditions.tsx"
    "src/components/procedure-form/Step3DocumentsRequired.tsx"
    "src/components/procedure-form/Step4ModalsDelays.tsx"
    "src/components/procedure-form/Step5DigitizationModalities.tsx"
    "src/components/procedure-form/Step6AdditionalInfo.tsx"
    "src/components/procedure-form/StepIndicator.tsx"
    "src/components/procedure-form/types.ts"
    "src/components/ProcedureComparisonSection.tsx"
    "src/components/procedures/ProceduresEnrichmentTab.tsx"
    "src/components/search/AdvancedSearchFilters.tsx"
    "src/components/search/SearchInterface.tsx"
    "src/components/sections/OptimizedSectionTemplate.tsx"
    "src/components/ui/sonner.tsx"
    "src/components/ui/tooltip.tsx"
    "src/components/writing/OptimizedConsolidatedProceduresSection.tsx"
    "src/components/writing/OptimizedConsolidatedTextsSection.tsx"
    "src/hooks/useEnhancedValidation.ts"
    "src/hooks/useErrorBoundary.tsx"
    "src/hooks/useErrorHandler.ts"
    "src/hooks/useModalError.ts"
    "src/hooks/useModals.ts"
    "src/hooks/useOptimizedModal.ts"
    "src/hooks/useOptimizedSearch.ts"
    "src/hooks/useOptimizedState.ts"
    "src/hooks/useSecureForm.ts"
    "src/hooks/useSecureState.ts"
    "src/i18n/index.ts"
    "src/layout/ContentRenderer.tsx"
    "src/schemas/authSchemas.ts"
    "src/services/dataService.ts"
    "src/store/globalStore.ts"
    "src/utils/advancedCaching.ts"
    "src/utils/analytics/dataCollector.ts"
    "src/utils/analytics/reportGenerator.ts"
    "src/utils/analytics/types.ts"
    "src/utils/analyticsMonitor.ts"
    "src/utils/cleanupObsoleteFiles.ts"
    "src/utils/codeOptimizer.ts"
    "src/utils/dataCompression.ts"
    "src/utils/edgeComputing.ts"
    "src/utils/enhancedCache.ts"
    "src/utils/errorBoundary.ts"
    "src/utils/modalAnimations.ts"
    "src/utils/optimizedLazyLoading.ts"
    "src/utils/performance.ts"
    "src/utils/realtimeIndexing.ts"
    "src/utils/resourceMonitor.ts"
    "src/utils/security.ts"
    "src/utils/smartCache.ts"
    "src/utils/testing/hooks.ts"
    "src/utils/testing/index.ts"
    "src/utils/testing/testRunner.ts"
    "src/utils/testing/testSuites.ts"
    "src/utils/testing/types.ts"
    "src/utils/testUtils.ts"
    "src/utils/unifiedCacheManager.ts"
    "src/utils/validation.ts"
    "src/utils/validation/sanitizers.ts"
    "src/utils/validation/validationRules.ts"
)

# Dépendances inutilisées
UNUSED_DEPS=(
    "@hookform/resolvers"
    "@radix-ui/react-tooltip"
    "@tanstack/react-query"
    "@types/react-window"
    "next-themes"
    "pdf-poppler"
    "react-i18next"
    "react-is"
    "react-window"
    "sonner"
    "tailwindcss-animate"
)

print_success "Analyse terminée : ${#UNUSED_FILES[@]} fichiers et ${#UNUSED_DEPS[@]} dépendances à nettoyer"

# Création du répertoire de sauvegarde
if [ "$DRY_RUN" = false ]; then
    mkdir -p "$BACKUP_DIR"
    print_success "Répertoire de sauvegarde créé : $BACKUP_DIR"
fi

# 1. Nettoyage des fichiers inutilisés
print_section "NETTOYAGE DES FICHIERS INUTILISÉS"

if confirm_action "Supprimer ${#UNUSED_FILES[@]} fichiers inutilisés ?"; then
    removed_count=0
    total_size=0
    
    for file in "${UNUSED_FILES[@]}"; do
        if [ -f "$file" ]; then
            size=$(stat -c%s "$file" 2>/dev/null || echo "0")
            total_size=$((total_size + size))
            
            if [ "$DRY_RUN" = true ]; then
                echo "  🗑️  SERAIT SUPPRIMÉ: $file ($(numfmt --to=iec $size))"
            else
                # Créer la structure de répertoire dans la sauvegarde
                backup_path="$BACKUP_DIR/$(dirname "$file")"
                mkdir -p "$backup_path"
                
                # Sauvegarder le fichier
                cp "$file" "$backup_path/"
                
                # Supprimer le fichier
                rm "$file"
                removed_count=$((removed_count + 1))
                echo "  ✅ Supprimé: $file ($(numfmt --to=iec $size))"
            fi
        else
            echo "  ⚠️  Fichier déjà absent: $file"
        fi
    done
    
    if [ "$DRY_RUN" = false ]; then
        print_success "$removed_count fichiers supprimés ($(numfmt --to=iec $total_size) libérés)"
    else
        print_info "SIMULATION: $removed_count fichiers seraient supprimés ($(numfmt --to=iec $total_size) seraient libérés)"
    fi
else
    print_info "Nettoyage des fichiers annulé"
fi

# 2. Nettoyage des dépendances inutilisées
if [ "$CLEAN_DEPS" = true ]; then
    print_section "NETTOYAGE DES DÉPENDANCES INUTILISÉES"
    
    if confirm_action "Supprimer ${#UNUSED_DEPS[@]} dépendances inutilisées ?"; then
        if [ "$DRY_RUN" = false ]; then
            for dep in "${UNUSED_DEPS[@]}"; do
                echo "  🗑️  Suppression de $dep..."
                npm uninstall "$dep" --silent 2>/dev/null || echo "    ⚠️  Erreur lors de la suppression de $dep"
            done
            print_success "Dépendances supprimées"
        else
            for dep in "${UNUSED_DEPS[@]}"; do
                echo "  🗑️  SERAIT SUPPRIMÉ: $dep"
            done
            print_info "SIMULATION: ${#UNUSED_DEPS[@]} dépendances seraient supprimées"
        fi
    else
        print_info "Nettoyage des dépendances annulé"
    fi
fi

# 3. Nettoyage des répertoires vides
print_section "NETTOYAGE DES RÉPERTOIRES VIDES"

if [ "$DRY_RUN" = false ]; then
    empty_dirs=$(find src -type d -empty 2>/dev/null)
    if [ -n "$empty_dirs" ]; then
        echo "$empty_dirs" | while read -r dir; do
            rmdir "$dir" 2>/dev/null && echo "  ✅ Répertoire vide supprimé: $dir"
        done
    else
        print_success "Aucun répertoire vide trouvé"
    fi
else
    empty_dirs=$(find src -type d -empty 2>/dev/null)
    if [ -n "$empty_dirs" ]; then
        echo "$empty_dirs" | while read -r dir; do
            echo "  🗑️  SERAIT SUPPRIMÉ: $dir (répertoire vide)"
        done
    else
        print_info "SIMULATION: Aucun répertoire vide trouvé"
    fi
fi

# 4. Vérification finale
print_section "VÉRIFICATION FINALE"

if [ "$DRY_RUN" = false ]; then
    print_info "Test de compilation..."
    if npm run build >/dev/null 2>&1; then
        print_success "✅ La compilation fonctionne encore après nettoyage"
    else
        print_error "❌ Erreur de compilation détectée !"
        echo "💡 Vous pouvez restaurer les fichiers depuis : $BACKUP_DIR"
        exit 1
    fi
    
    # Nettoyer le build de test
    rm -rf dist build 2>/dev/null
fi

# 5. Rapport final
print_section "RAPPORT FINAL"

if [ "$DRY_RUN" = false ]; then
    backup_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
    current_size=$(du -sh src 2>/dev/null | cut -f1)
    
    echo "📊 Résultats du nettoyage :"
    echo "  - Fichiers sauvegardés dans: $BACKUP_DIR ($backup_size)"
    echo "  - Taille actuelle du src/: $current_size"
    echo "  - Fichiers supprimés: ${#UNUSED_FILES[@]}"
    
    if [ "$CLEAN_DEPS" = true ]; then
        echo "  - Dépendances supprimées: ${#UNUSED_DEPS[@]}"
    fi
    
    echo ""
    echo "💡 Commandes utiles :"
    echo "  - Restaurer tout: cp -r $BACKUP_DIR/src/* src/"
    echo "  - Supprimer la sauvegarde: rm -rf $BACKUP_DIR"
    echo "  - Réinstaller les dépendances: npm install"
    echo "  - Vérifier à nouveau: npx unimported"
    
    print_success "Nettoyage terminé avec succès !"
else
    echo "📊 Simulation terminée :"
    echo "  - Fichiers qui seraient supprimés: ${#UNUSED_FILES[@]}"
    if [ "$CLEAN_DEPS" = true ]; then
        echo "  - Dépendances qui seraient supprimées: ${#UNUSED_DEPS[@]}"
    fi
    echo ""
    echo "💡 Pour effectuer le nettoyage réel :"
    echo "  - Fichiers seulement: $0"
    echo "  - Avec dépendances: $0 --with-deps"
    echo "  - Mode automatique: $0 --auto"
fi

echo ""
echo "🏁 Nettoyage terminé - $(date)"