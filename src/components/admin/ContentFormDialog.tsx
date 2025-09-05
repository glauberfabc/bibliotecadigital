'use client';

import { zodResolver } from '@hookform/resolvers/zod';
import { useForm } from 'react-hook-form';
import * as z from 'zod';
import { Button } from '@/components/ui/button';
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { useToast } from '@/hooks/use-toast';
import { type Content } from '@/lib/types';
import { useState, useEffect } from 'react';
import { Loader2 } from 'lucide-react';
import { upsertContentAction } from '@/app/admin/actions';

const formSchema = z.object({
  title: z.string().min(2, { message: 'O título deve ter pelo menos 2 caracteres.' }),
  theme: z.string().min(1, { message: 'Por favor, selecione um tema.' }),
  type: z.enum(['book', 'audiobook']),
  download_url: z.string().url({ message: 'Por favor, insira uma URL válida.' }),
});

const themes = ['Saúde', 'Negócios', 'Romance', 'Ficção Científica', 'Fantasia', 'Autoajuda', 'Biografia'];

type ContentFormDialogProps = {
  isOpen: boolean;
  setIsOpen: (open: boolean) => void;
  initialData?: Content;
};

export default function ContentFormDialog({
  isOpen,
  setIsOpen,
  initialData,
}: ContentFormDialogProps) {
  const { toast } = useToast();
  const [isLoading, setIsLoading] = useState(false);
  const [coverFile, setCoverFile] = useState<File | null>(null);

  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      title: '',
      theme: '',
      type: 'book',
      download_url: '',
    },
  });

  useEffect(() => {
    if (initialData) {
      form.reset({
        title: initialData.title,
        theme: initialData.theme,
        type: initialData.type,
        download_url: initialData.download_url,
      });
    } else {
      form.reset({
        title: '',
        theme: '',
        type: 'book',
        download_url: '',
      });
    }
    setCoverFile(null);
  }, [initialData, form, isOpen]);

  const handleOpenChange = (open: boolean) => {
    if (!isLoading) {
      setIsOpen(open);
    }
  };

  async function onSubmit(values: z.infer<typeof formSchema>) {
    setIsLoading(true);

    if (!coverFile && !initialData) {
      toast({ title: 'Erro', description: 'Por favor, selecione uma imagem de capa.', variant: 'destructive' });
      setIsLoading(false);
      return;
    }

    const formData = new FormData();
    formData.append('id', initialData?.id || '');
    formData.append('title', values.title);
    formData.append('theme', values.theme);
    formData.append('type', values.type);
    formData.append('download_url', values.download_url);
    if(coverFile) {
        formData.append('cover_image', coverFile);
    }
    if (initialData?.cover_url) {
        formData.append('existing_cover_url', initialData.cover_url);
    }

    const result = await upsertContentAction(formData);

    if (result.success) {
      toast({
        title: 'Sucesso!',
        description: `Conteúdo ${initialData ? 'atualizado' : 'criado'}.`,
      });
      setIsOpen(false);
    } else {
      toast({
        title: 'Erro',
        description: result.error,
        variant: 'destructive',
      });
    }

    setIsLoading(false);
  }

  return (
    <Dialog open={isOpen} onOpenChange={handleOpenChange}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle className="font-headline">{initialData ? 'Editar Conteúdo' : 'Adicionar Novo Conteúdo'}</DialogTitle>
          <DialogDescription>
            {initialData ? 'Atualize os detalhes do conteúdo.' : 'Preencha o formulário para adicionar um novo item à biblioteca.'}
          </DialogDescription>
        </DialogHeader>
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            <FormField control={form.control} name="title" render={({ field }) => (
                <FormItem>
                  <FormLabel>Título</FormLabel>
                  <FormControl><Input placeholder="O Grande Gatsby" {...field} /></FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            <FormField control={form.control} name="theme" render={({ field }) => (
                <FormItem>
                  <FormLabel>Tema</FormLabel>
                   <Select onValueChange={field.onChange} defaultValue={field.value}>
                    <FormControl><SelectTrigger><SelectValue placeholder="Selecione um tema" /></SelectTrigger></FormControl>
                    <SelectContent>
                      {themes.map(theme => <SelectItem key={theme} value={theme}>{theme}</SelectItem>)}
                    </SelectContent>
                  </Select>
                  <FormMessage />
                </FormItem>
              )}
            />
             <FormField control={form.control} name="type" render={({ field }) => (
                <FormItem>
                  <FormLabel>Tipo</FormLabel>
                   <Select onValueChange={field.onChange} defaultValue={field.value}>
                    <FormControl><SelectTrigger><SelectValue placeholder="Selecione um tipo" /></SelectTrigger></FormControl>
                    <SelectContent>
                      <SelectItem value="book">Livro</SelectItem>
                      <SelectItem value="audiobook">Audiolivro</SelectItem>
                    </SelectContent>
                  </Select>
                  <FormMessage />
                </FormItem>
              )}
            />
            <FormField control={form.control} name="download_url" render={({ field }) => (
                <FormItem>
                  <FormLabel>URL de Download</FormLabel>
                  <FormControl><Input placeholder="https://exemplo.com/download" {...field} /></FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            <FormItem>
              <FormLabel>Imagem de Capa</FormLabel>
              <FormControl><Input type="file" accept="image/*" onChange={e => setCoverFile(e.target.files?.[0] || null)} /></FormControl>
              <FormMessage />
            </FormItem>
            <DialogFooter>
              <Button type="button" variant="ghost" onClick={() => handleOpenChange(false)} disabled={isLoading}>Cancelar</Button>
              <Button type="submit" disabled={isLoading}>
                {isLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                {initialData ? 'Salvar Alterações' : 'Criar'}
              </Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  );
}
