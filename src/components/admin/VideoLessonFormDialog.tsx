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
import { useToast } from '@/hooks/use-toast';
import { type VideoLesson } from '@/lib/types';
import { useState, useEffect } from 'react';
import { Loader2 } from 'lucide-react';
import { upsertVideoLessonAction } from '@/app/admin/actions';

const formSchema = z.object({
  title: z.string().min(2, { message: 'O título deve ter pelo menos 2 caracteres.' }),
  youtube_url: z.string().url({ message: 'Por favor, insira uma URL do YouTube válida.' }),
});

type VideoLessonFormDialogProps = {
  isOpen: boolean;
  setIsOpen: (open: boolean) => void;
  initialData?: VideoLesson;
};

export default function VideoLessonFormDialog({
  isOpen,
  setIsOpen,
  initialData,
}: VideoLessonFormDialogProps) {
  const { toast } = useToast();
  const [isLoading, setIsLoading] = useState(false);

  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      title: '',
      youtube_url: '',
    },
  });

  useEffect(() => {
    if (initialData) {
      form.reset(initialData);
    } else {
      form.reset({
        title: '',
        youtube_url: '',
      });
    }
  }, [initialData, form, isOpen]);

  const handleOpenChange = (open: boolean) => {
    if (!isLoading) {
      setIsOpen(open);
    }
  };

  async function onSubmit(values: z.infer<typeof formSchema>) {
    setIsLoading(true);

    const result = await upsertVideoLessonAction({
        id: initialData?.id,
        ...values,
    });

    if (result.success) {
      toast({
        title: 'Sucesso!',
        description: `Aula ${initialData ? 'atualizada' : 'criada'}.`,
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
          <DialogTitle className="font-headline">{initialData ? 'Editar Aula' : 'Adicionar Nova Aula'}</DialogTitle>
          <DialogDescription>
            {initialData ? 'Atualize os detalhes da aula.' : 'Preencha o formulário para adicionar uma nova aula.'}
          </DialogDescription>
        </DialogHeader>
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            <FormField control={form.control} name="title" render={({ field }) => (
                <FormItem>
                  <FormLabel>Título</FormLabel>
                  <FormControl><Input placeholder="Título da Aula" {...field} /></FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            <FormField control={form.control} name="youtube_url" render={({ field }) => (
                <FormItem>
                  <FormLabel>URL do YouTube</FormLabel>
                  <FormControl><Input placeholder="https://www.youtube.com/watch?v=..." {...field} /></FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
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
