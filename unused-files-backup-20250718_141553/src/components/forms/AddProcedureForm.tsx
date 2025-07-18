
import React, { useState, useEffect } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Switch } from '@/components/ui/switch';
import { useToast } from '@/hooks/use-toast';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { useFormLibraryStore, SavedForm } from '@/stores/formLibraryStore';

interface AddProcedureFormProps {
  isOpen: boolean;
  onClose: () => void;
}

export function AddProcedureForm({ isOpen, onClose }: AddProcedureFormProps) {
  const { toast } = useToast();
  const { forms: customForms } = useFormLibraryStore();
  const [selectedFormId, setSelectedFormId] = useState('');
  const [selectedForm, setSelectedForm] = useState<SavedForm | null>(null);
  const [formData, setFormData] = useState<{ [key: string]: any }>({});

  // Filtrer les formulaires de la bibliothèque pour les procédures administratives
  console.log('=== DEBUG AddProcedureForm ===');
  console.log('Nombre total de formulaires dans la bibliothèque:', customForms.length);
  console.log('Tous les formulaires dans la bibliothèque:', customForms.map(f => ({ id: f.id, name: f.name, type: f.type, category: f.category })));
  
  const procedureForms = customForms.filter(form => {
    const match = form.type === 'procedures_administratives' || form.category === 'Procédures Administratives';
    console.log(`Formulaire ${form.name}: type="${form.type}", category="${form.category}", match=${match}`);
    return match;
  });
  
  console.log('Formulaires de procédures administratives filtrés:', procedureForms.length);
  console.log('Liste détaillée:', procedureForms.map(f => ({ id: f.id, name: f.name, type: f.type, category: f.category })));

  // Déduplication par nom pour éviter les doublons
  const uniqueProcedureForms = procedureForms.reduce((acc: SavedForm[], current) => {
    const exists = acc.find(form => form.name.toLowerCase() === current.name.toLowerCase());
    if (!exists) {
      acc.push(current);
    }
    return acc;
  }, []);

  console.log('Formulaires de procédures trouvés:', procedureForms.length);
  console.log('Formulaires uniques après déduplication:', uniqueProcedureForms.length);
  console.log('Liste des formulaires:', uniqueProcedureForms.map(f => ({ id: f.id, name: f.name, type: f.type, category: f.category })));

  useEffect(() => {
    if (selectedFormId) {
      const form = uniqueProcedureForms.find(f => f.id === selectedFormId);
      console.log('Formulaire sélectionné:', form);
      if (form) {
        setSelectedForm(form);
        // Initialiser les données du formulaire avec des valeurs vides
        const initialData: { [key: string]: any } = {};
        form.fields.forEach(field => {
          initialData[field.name] = '';
        });
        setFormData(initialData);
        console.log('Données du formulaire initialisées:', initialData);
      }
    } else {
      setSelectedForm(null);
      setFormData({});
    }
  }, [selectedFormId, uniqueProcedureForms]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedForm) {
      toast({
        title: "Erreur",
        description: "Veuillez sélectionner une catégorie de procédure depuis la bibliothèque.",
        variant: "destructive"
      });
      return;
    }
    
    console.log('Nouvelle procédure administrative:', { formTemplate: selectedForm, data: formData });
    toast({
      title: "Procédure ajoutée",
      description: `La procédure basée sur "${selectedForm.name}" a été ajoutée avec succès.`,
    });
    onClose();
    setSelectedFormId('');
    setSelectedForm(null);
    setFormData({});
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Ajouter une nouvelle procédure administrative</DialogTitle>
        </DialogHeader>
        
        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Sélection de la catégorie de procédure */}
          <Card>
            <CardHeader>
              <CardTitle>Sélection de la catégorie de procédure</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <div>
                  <Label htmlFor="form-select">Catégorie de procédure * ({uniqueProcedureForms.length} disponibles)</Label>
                  <Select value={selectedFormId} onValueChange={setSelectedFormId}>
                    <SelectTrigger>
                      <SelectValue placeholder="Sélectionner une catégorie de procédure depuis la bibliothèque" />
                    </SelectTrigger>
                    <SelectContent>
                      {uniqueProcedureForms.length === 0 ? (
                        <SelectItem value="" disabled>
                          Aucun formulaire de procédure administrative disponible dans la bibliothèque
                        </SelectItem>
                      ) : (
                        uniqueProcedureForms.map((form) => (
                          <SelectItem key={form.id} value={form.id}>
                            {form.name} ({form.type})
                          </SelectItem>
                        ))
                      )}
                    </SelectContent>
                  </Select>
                </div>
                {selectedForm && (
                  <div className="p-3 bg-green-50 rounded-lg">
                    <p className="text-sm text-green-800">
                      <strong>Description:</strong> {selectedForm.description}
                    </p>
                    <p className="text-sm text-green-700 mt-1">
                      <strong>Champs:</strong> {selectedForm.fields.length} champs configurés
                    </p>
                    <p className="text-sm text-green-700 mt-1">
                      <strong>Type:</strong> {selectedForm.type}
                    </p>
                    <p className="text-sm text-green-700 mt-1">
                      <strong>Catégorie:</strong> {selectedForm.category}
                    </p>
                  </div>
                )}
              </div>
            </CardContent>
          </Card>

          {/* Formulaire dynamique basé sur la sélection */}
          {selectedForm && (
            <Card>
              <CardHeader>
                <CardTitle>Détails de la procédure administrative - {selectedForm.name}</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {selectedForm.fields.map((field) => (
                    <div key={field.name} className={field.type === 'textarea' ? 'md:col-span-2' : ''}>
                      <Label htmlFor={field.name}>
                        {field.label} {field.required && <span className="text-red-500">*</span>}
                      </Label>
                      {field.type === 'textarea' ? (
                        <Textarea
                          id={field.name}
                          value={formData[field.name] || ''}
                          onChange={(e) => setFormData({...formData, [field.name]: e.target.value})}
                          placeholder={field.placeholder}
                          required={field.required}
                          rows={3}
                        />
                      ) : field.type === 'select' && field.options ? (
                        <Select 
                          value={formData[field.name] || ''} 
                          onValueChange={(value) => setFormData({...formData, [field.name]: value})}
                        >
                          <SelectTrigger>
                            <SelectValue placeholder={field.placeholder || `Sélectionner ${field.label.toLowerCase()}`} />
                          </SelectTrigger>
                          <SelectContent>
                            {field.options.map((option) => (
                              <SelectItem key={option} value={option}>
                                {option}
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                      ) : field.type === 'checkbox' ? (
                        <div className="flex items-center space-x-2">
                          <Switch
                            id={field.name}
                            checked={formData[field.name] || false}
                            onCheckedChange={(checked) => setFormData({...formData, [field.name]: checked})}
                          />
                          <Label htmlFor={field.name}>{field.placeholder || field.label}</Label>
                        </div>
                      ) : (
                        <Input
                          id={field.name}
                          type={field.type || 'text'}
                          value={formData[field.name] || ''}
                          onChange={(e) => setFormData({...formData, [field.name]: e.target.value})}
                          placeholder={field.placeholder}
                          required={field.required}
                        />
                      )}
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}

          <div className="flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={onClose}>
              Annuler
            </Button>
            <Button type="submit" disabled={!selectedForm}>
              Ajouter la procédure
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
