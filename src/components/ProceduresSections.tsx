
import { useState, useEffect } from 'react';
import { ClipboardList } from 'lucide-react';
import { SectionHeader } from './common/SectionHeader';
import { ProceduresTabs } from './ProceduresTabs';
import { ProcedureForm } from './ProcedureForm';
import { ProcedureSummaryModal } from './ProcedureSummaryModal';
import { ApprovalModal } from './ApprovalModal';
import { ApprovalQueueModal } from './ApprovalQueueModal';

interface ProceduresSectionsProps {
  section: string;
  language: string;
}

export function ProceduresSections({ section, language }: ProceduresSectionsProps) {
  const [showAddForm, setShowAddForm] = useState(false);
  const [showSummaryModal, setShowSummaryModal] = useState(false);
  const [showApprovalModal, setShowApprovalModal] = useState(false);
  const [showApprovalQueue, setShowApprovalQueue] = useState(false);
  const [procedureData, setProcedureData] = useState(null);
  const [ocrData, setOcrData] = useState<any>(null);
  const [formInputMethod, setFormInputMethod] = useState<'manual' | 'ocr'>('manual');

  // Écouter l'événement pour ouvrir le formulaire en mode OCR
  useEffect(() => {
    const handleOpenProcedureFormOCR = () => {
      console.log('Ouverture du formulaire de procédure en mode OCR');
      setFormInputMethod('ocr');
      setShowAddForm(true);
    };

    const handleNavigateWithOCR = (event: CustomEvent) => {
      console.log('🎯 [ProceduresSections] Réception événement OCR:', event.detail);
      setOcrData(event.detail.ocrData);
      setFormInputMethod('ocr');
      setShowAddForm(true);
    };

    window.addEventListener('open-procedure-form-with-ocr', handleOpenProcedureFormOCR);
    window.addEventListener('navigate-to-procedure-form-with-ocr', handleNavigateWithOCR as EventListener);
    
    return () => {
      window.removeEventListener('open-procedure-form-with-ocr', handleOpenProcedureFormOCR);
      window.removeEventListener('navigate-to-procedure-form-with-ocr', handleNavigateWithOCR as EventListener);
    };
  }, []);

  const handleOCRDataExtracted = (data: { documentType: 'legal' | 'procedure', formData: Record<string, any> }) => {
    console.log('🎯 [ProceduresSections] Données OCR reçues:', data);
    
    if (data.documentType === 'procedure') {
      console.log('📋 [ProceduresSections] Navigation vers le formulaire de procédure avec données OCR');
      setOcrData(data.formData);
      setFormInputMethod('ocr');
      setShowAddForm(true);
    } else {
      console.warn('⚠️ [ProceduresSections] Type de document non compatible avec les procédures');
    }
  };

  const handleAddProcedure = () => {
    console.log('Fonction handleAddProcedure appelée');
    setFormInputMethod('manual');
    setShowAddForm(true);
  };

  const handleCloseForm = () => {
    setShowAddForm(false);
    setFormInputMethod('manual');
    setOcrData(null);
  };

  const handleProcedureSubmitted = (data: any) => {
    setProcedureData(data);
    setShowAddForm(false);
    setFormInputMethod('manual');
    setOcrData(null);
    setShowApprovalModal(true);
  };

  const handleCloseSummaryModal = () => {
    setShowSummaryModal(false);
    setProcedureData(null);
  };

  const handleAddAnotherProcedure = () => {
    setShowSummaryModal(false);
    setProcedureData(null);
    setShowAddForm(true);
  };

  const handleApprove = (comment?: string) => {
    console.log('Procédure approuvée:', procedureData, 'Commentaire:', comment);
    setShowApprovalModal(false);
    setShowSummaryModal(true);
  };

  const handleReject = (reason: string) => {
    console.log('Procédure rejetée:', procedureData, 'Raison:', reason);
    setShowApprovalModal(false);
    setProcedureData(null);
  };

  const handleOpenApprovalQueue = () => {
    console.log('Fonction handleOpenApprovalQueue appelée dans ProceduresSections');
    setShowApprovalQueue(true);
  };

  const handleApproveFromQueue = (item: any, comment?: string) => {
    console.log('Approuvé depuis la file:', item, comment);
    // Ici vous pouvez ajouter la logique pour approuver l'élément
  };

  const handleRejectFromQueue = (item: any, reason: string) => {
    console.log('Rejeté depuis la file:', item, reason);
    // Ici vous pouvez ajouter la logique pour rejeter l'élément
  };

  const handleViewFromQueue = (item: any) => {
    console.log('Examen depuis la file:', item);
    setProcedureData(item.data);
    setShowApprovalQueue(false);
    setShowApprovalModal(true);
  };

  const getSectionTitle = () => {
    const titles = {
      fr: {
        'procedures-catalog': 'Catalogue des Procédures Administratives',
        'procedures-enrichment': 'Alimentation de la Banque de Données',
        'procedures-search': 'Recherche de Procédures',
        'procedures-resources': 'Ressources Procédurales'
      },
      ar: {
        'procedures-catalog': 'كتالوج الإجراءات الإدارية',
        'procedures-enrichment': 'إثراء قاعدة البيانات',
        'procedures-search': 'البحث في الإجراءات',
        'procedures-resources': 'موارد الإجراءات'
      },
      en: {
        'procedures-catalog': 'Administrative Procedures Catalog',
        'procedures-enrichment': 'Database Enrichment',
        'procedures-search': 'Procedures Search',
        'procedures-resources': 'Procedural Resources'
      }
    };
    return titles[language as keyof typeof titles]?.[section as keyof typeof titles['fr']] || 'Procédures Administratives';
  };

  const getSectionDescription = () => {
    const descriptions = {
      fr: {
        'procedures-catalog': 'Explorez le catalogue complet des procédures administratives algériennes.',
        'procedures-enrichment': 'Contribuez à l\'enrichissement de la base de données procédurales.',
        'procedures-search': 'Recherchez parmi toutes les procédures administratives disponibles.',
        'procedures-resources': 'Accédez aux ressources et outils liés aux procédures administratives.'
      },
      ar: {
        'procedures-catalog': 'استكشف الكتالوج الكامل للإجراءات الإدارية الجزائرية.',
        'procedures-enrichment': 'ساهم في إثراء قاعدة بيانات الإجراءات.',
        'procedures-search': 'ابحث في جميع الإجراءات الإدارية المتاحة.',
        'procedures-resources': 'اطلع على الموارد والأدوات المتعلقة بالإجراءات الإدارية.'
      },
      en: {
        'procedures-catalog': 'Explore the complete catalog of Algerian administrative procedures.',
        'procedures-enrichment': 'Contribute to enriching the procedural database.',
        'procedures-search': 'Search through all available administrative procedures.',
        'procedures-resources': 'Access resources and tools related to administrative procedures.'
      }
    };
    return descriptions[language as keyof typeof descriptions]?.[section as keyof typeof descriptions['fr']];
  };

  if (showAddForm) {
    return (
      <ProcedureForm 
        onClose={handleCloseForm} 
        onSubmit={handleProcedureSubmitted}
        initialInputMethod={formInputMethod}
        ocrData={ocrData}
      />
    );
  }

  return (
    <div className="space-y-6">
      <SectionHeader
        title={getSectionTitle()}
        description={getSectionDescription()}
        icon={ClipboardList}
        iconColor="text-blue-600"
      />
      
      <ProceduresTabs 
        section={section} 
        onAddProcedure={handleAddProcedure}
        onOpenApprovalQueue={handleOpenApprovalQueue}
        onOCRDataExtracted={handleOCRDataExtracted}
      />
      
      <ProcedureSummaryModal
        isOpen={showSummaryModal}
        onClose={handleCloseSummaryModal}
        onAddAnother={handleAddAnotherProcedure}
        procedureData={procedureData}
      />

      <ApprovalModal
        isOpen={showApprovalModal}
        onClose={() => setShowApprovalModal(false)}
        onApprove={handleApprove}
        onReject={handleReject}
        data={procedureData}
        type="procedure"
      />

      <ApprovalQueueModal
        isOpen={showApprovalQueue}
        onClose={() => setShowApprovalQueue(false)}
        onApproveItem={handleApproveFromQueue}
        onRejectItem={handleRejectFromQueue}
        onViewItem={handleViewFromQueue}
        filterType="procedure"
      />
    </div>
  );
}
