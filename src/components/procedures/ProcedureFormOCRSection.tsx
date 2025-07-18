import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Scan } from 'lucide-react';
import { SmartOCRProcessor } from '@/components/common/SmartOCRProcessor';

interface ProcedureFormOCRSectionProps {
  showOCRScanner: boolean;
  onShowOCRScanner: (show: boolean) => void;
  onOCRFormDataExtracted: (data: { documentType: 'legal' | 'procedure', formData: Record<string, any> }) => void;
}

export function ProcedureFormOCRSection({ 
  showOCRScanner, 
  onShowOCRScanner, 
  onOCRFormDataExtracted 
}: ProcedureFormOCRSectionProps) {
  
  const handleOCRFormDataExtracted = (data: { documentType: 'legal' | 'procedure', formData: Record<string, any> }) => {
    console.log('🎯 [ProcedureFormOCRSection] Données OCR extraites:', data);
    console.log('📋 [ProcedureFormOCRSection] Type de document:', data.documentType);
    console.log('📋 [ProcedureFormOCRSection] Nombre de champs:', Object.keys(data.formData).length);
    
    // Passer les données au parent AVANT de fermer le scanner
    try {
      console.log('📤 [ProcedureFormOCRSection] Transmission des données au parent...');
      onOCRFormDataExtracted(data);
      console.log('✅ [ProcedureFormOCRSection] Données transmises avec succès');
    } catch (error) {
      console.error('❌ [ProcedureFormOCRSection] Erreur lors de la transmission:', error);
    }
    
    // Fermer le scanner OCR après transmission
    setTimeout(() => {
      console.log('🔒 [ProcedureFormOCRSection] Fermeture du scanner');
      onShowOCRScanner(false);
    }, 100);
  };

  return (
    <Card className="shadow-lg border-0 bg-white/80 backdrop-blur-sm mb-8">
      <CardHeader className="border-b border-gray-100 bg-gradient-to-r from-blue-50 to-indigo-50">
        <CardTitle className="flex items-center gap-2">
          <Scan className="w-5 h-5 text-blue-600" />
          Scanner pour Générer une Procédure
        </CardTitle>
      </CardHeader>
      <CardContent className="p-6">
        <SmartOCRProcessor
          onFormDataExtracted={handleOCRFormDataExtracted}
          onClose={() => onShowOCRScanner(false)}
          title="Scanner pour Générer une Procédure"
        />
      </CardContent>
    </Card>
  );
}