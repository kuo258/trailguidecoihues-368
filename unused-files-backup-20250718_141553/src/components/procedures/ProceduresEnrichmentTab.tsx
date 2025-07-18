
import { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Plus, Upload, Wand2, Database, Scan } from 'lucide-react';
import { SmartOCRProcessor } from '@/components/common/SmartOCRProcessor';
import { useGlobalActions } from '@/hooks/useGlobalActions';

interface ProceduresEnrichmentTabProps {
  onAddProcedure: () => void;
  onOCRTextExtracted?: (text: string) => void;
  onOCRDataExtracted?: (data: { documentType: 'legal' | 'procedure', formData: Record<string, any> }) => void;
}

export function ProceduresEnrichmentTab({ onAddProcedure, onOCRTextExtracted, onOCRDataExtracted }: ProceduresEnrichmentTabProps) {
  const [showOCRScanner, setShowOCRScanner] = useState(false);
  const actions = useGlobalActions();

  const handleSmartOCRDataExtracted = (data: { documentType: 'legal' | 'procedure', formData: Record<string, any> }) => {
    console.log('🎯 [ProceduresEnrichmentTab] Données OCR extraites:', data);
    console.log('📋 [ProceduresEnrichmentTab] Type de document:', data.documentType);
    console.log('📋 [ProceduresEnrichmentTab] Nombre de champs:', Object.keys(data.formData).length);
    
    // Passer les données au parent AVANT de fermer le scanner
    try {
      console.log('📤 [ProceduresEnrichmentTab] Transmission des données au parent...');
      if (onOCRDataExtracted) {
        onOCRDataExtracted(data);
      }
      console.log('✅ [ProceduresEnrichmentTab] Données transmises avec succès');
    } catch (error) {
      console.error('❌ [ProceduresEnrichmentTab] Erreur lors de la transmission:', error);
    }
    
    // Fermer le scanner après transmission
    setTimeout(() => {
      console.log('🔒 [ProceduresEnrichmentTab] Fermeture du scanner');
      setShowOCRScanner(false);
    }, 100);
  };

  const handleScanOCRClick = () => {
    setShowOCRScanner(true);
  };

  if (showOCRScanner) {
    return (
      <SmartOCRProcessor
        title="Scanner un document de procédure"
        onFormDataExtracted={handleSmartOCRDataExtracted}
        onClose={() => setShowOCRScanner(false)}
      />
    );
  }

  const handleImportCSVExcel = () => {
    actions.handleImport(['.csv', '.xlsx', '.xls']);
  };

  const handleAutoFill = () => {
    const event = new CustomEvent('open-modal', {
      detail: {
        type: 'ai-generation',
        title: 'Auto-remplissage intelligent',
        data: { feature: 'auto-fill', context: 'procedures' }
      }
    });
    window.dispatchEvent(event);
  };

  return (
    <div className="space-y-8">
      {/* Section principale avec les 2 choix principaux */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
        {/* Option Manuelle */}
        <Card className="shadow-lg border-0 bg-gradient-to-br from-emerald-50 to-green-50 hover:shadow-xl transition-all duration-300 cursor-pointer group" onClick={onAddProcedure}>
          <CardHeader className="text-center p-8">
            <div className="w-20 h-20 bg-emerald-100 rounded-full flex items-center justify-center mx-auto mb-6 group-hover:bg-emerald-200 transition-colors">
              <Plus className="w-10 h-10 text-emerald-600" />
            </div>
            <CardTitle className="text-2xl text-gray-900 mb-2">Saisie Manuelle</CardTitle>
            <CardDescription className="text-gray-600 text-lg">
              Saisir manuellement une nouvelle procédure administrative via le formulaire complet
            </CardDescription>
          </CardHeader>
          <CardContent className="px-8 pb-8">
            <Button 
              className="w-full h-12 bg-emerald-600 hover:bg-emerald-700 text-white font-medium" 
              onClick={onAddProcedure}
            >
              <Plus className="w-5 h-5 mr-3" />
              Formulaire Manuel
            </Button>
          </CardContent>
        </Card>

        {/* Option OCR */}
        <Card className="shadow-lg border-0 bg-gradient-to-br from-blue-50 to-purple-50 hover:shadow-xl transition-all duration-300 cursor-pointer group" onClick={handleScanOCRClick}>
          <CardHeader className="text-center p-8">
            <div className="w-20 h-20 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-6 group-hover:bg-blue-200 transition-colors">
              <Scan className="w-10 h-10 text-blue-600" />
            </div>
            <CardTitle className="text-2xl text-gray-900 mb-2">Scan OCR</CardTitle>
            <CardDescription className="text-gray-600 text-lg">
              Scanner et extraire automatiquement le contenu d'un document de procédure
            </CardDescription>
          </CardHeader>
          <CardContent className="px-8 pb-8">
            <Button 
              className="w-full h-12 bg-blue-600 hover:bg-blue-700 text-white font-medium" 
              onClick={handleScanOCRClick}
            >
              <Scan className="w-5 h-5 mr-3" />
              Scanner Document
            </Button>
          </CardContent>
        </Card>
      </div>

      {/* Autres options d'enrichissement */}
      <div>
        <h3 className="text-xl font-semibold text-gray-900 mb-6">Options d'enrichissement avancées</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <Card className="hover:shadow-md transition-shadow cursor-pointer border-gray-200" onClick={handleImportCSVExcel}>
            <CardHeader className="text-center">
              <Upload className="w-12 h-12 mx-auto text-blue-600 mb-4" />
              <CardTitle className="text-lg">Import en lot</CardTitle>
              <CardDescription>
                Importer plusieurs procédures depuis un fichier Excel/CSV
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Button 
                variant="outline"
                className="w-full border-blue-300 text-blue-700 hover:bg-blue-50" 
                onClick={handleImportCSVExcel}
              >
                <Upload className="w-4 h-4 mr-2" />
                Import CSV/Excel
              </Button>
            </CardContent>
          </Card>

          <Card className="hover:shadow-md transition-shadow cursor-pointer border-gray-200" onClick={handleAutoFill}>
            <CardHeader className="text-center">
              <Wand2 className="w-12 h-12 mx-auto text-purple-600 mb-4" />
              <CardTitle className="text-lg">Auto-remplissage intelligent</CardTitle>
              <CardDescription>
                Remplissage automatique avec IA
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Button 
                variant="outline"
                className="w-full border-purple-300 text-purple-700 hover:bg-purple-50" 
                onClick={handleAutoFill}
              >
                <Wand2 className="w-4 h-4 mr-2" />
                Auto-remplissage
              </Button>
            </CardContent>
          </Card>

          <Card className="hover:shadow-md transition-shadow cursor-pointer border-gray-200" onClick={() => {
            const event = new CustomEvent('open-modal', {
              detail: {
                type: 'api-import',
                title: 'Import via API',
                data: { context: 'procedures' }
              }
            });
            window.dispatchEvent(event);
          }}>
            <CardHeader className="text-center">
              <Database className="w-12 h-12 mx-auto text-indigo-600 mb-4" />
              <CardTitle className="text-lg">Import API</CardTitle>
              <CardDescription>
                Importer le contenu depuis des sources API configurées
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Button 
                variant="outline"
                className="w-full border-indigo-300 text-indigo-700 hover:bg-indigo-50" 
                onClick={() => {
                  const event = new CustomEvent('open-modal', {
                    detail: {
                      type: 'api-import',
                      title: 'Import via API',
                      data: { context: 'procedures' }
                    }
                  });
                  window.dispatchEvent(event);
                }}
              >
                <Database className="w-4 h-4 mr-2" />
                Import API
              </Button>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
