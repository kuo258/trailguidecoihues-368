
import { ProcedureForm } from "@/components/ProcedureForm";

interface ProcedureFormViewProps {
  onBack: () => void;
  onSubmit: (data: any) => void;
  ocrData?: any;
  initialInputMethod?: 'manual' | 'ocr';
}

export function ProcedureFormView({ onBack, onSubmit, ocrData, initialInputMethod }: ProcedureFormViewProps) {
  return (
    <div className="space-y-6">
      <ProcedureForm 
        onClose={onBack} 
        onSubmit={onSubmit}
        ocrData={ocrData}
        initialInputMethod={initialInputMethod}
      />
    </div>
  );
}
