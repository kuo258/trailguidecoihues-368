import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Scan } from 'lucide-react';
import { SmartOCRProcessor } from '@/components/common/SmartOCRProcessor';

interface LegalTextFormOCRSectionProps {
  showOCRScanner: boolean;
  onShowOCRScanner: (show: boolean) => void;
  onOCRFormDataExtracted: (data: { documentType: 'legal' | 'procedure', formData: Record<string, any> }) => void;
}

export function LegalTextFormOCRSection({ 
  showOCRScanner, 
  onShowOCRScanner, 
  onOCRFormDataExtracted 
}: LegalTextFormOCRSectionProps) {
  
  const handleOCRFormDataExtracted = (data: { documentType: 'legal' | 'procedure', formData: Record<string, any> }) => {
    console.log('🎯 [LegalTextFormOCRSection] Données OCR extraites:', data);
    console.log('📋 [LegalTextFormOCRSection] Type de document:', data.documentType);
    console.log('📋 [LegalTextFormOCRSection] Nombre de champs:', Object.keys(data.formData).length);
    
    // Passer les données au parent AVANT de fermer le scanner
    try {
      console.log('📤 [LegalTextFormOCRSection] Transmission des données au parent...');
      onOCRFormDataExtracted(data);
      console.log('✅ [LegalTextFormOCRSection] Données transmises avec succès');
    } catch (error) {
      console.error('❌ [LegalTextFormOCRSection] Erreur lors de la transmission:', error);
    }
    
    // Fermer le scanner OCR après transmission
    setTimeout(() => {
      console.log('🔒 [LegalTextFormOCRSection] Fermeture du scanner');
      onShowOCRScanner(false);
    }, 100);
  };

  return (
    <Card className="shadow-lg border-0 bg-white/80 backdrop-blur-sm mb-8">
      <CardHeader className="border-b border-gray-100 bg-gradient-to-r from-green-50 to-emerald-50">
        <CardTitle className="flex items-center gap-2">
          <Scan className="w-5 h-5 text-green-600" />
          Scanner pour Générer un Texte Juridique
        </CardTitle>
      </CardHeader>
      <CardContent className="p-6">
        <SmartOCRProcessor
          onFormDataExtracted={handleOCRFormDataExtracted}
          onClose={() => onShowOCRScanner(false)}
          title="Scanner pour Générer un Texte Juridique"
        />
      </CardContent>
    </Card>
  );
}
