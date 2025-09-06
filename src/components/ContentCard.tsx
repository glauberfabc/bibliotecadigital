'use client';

import Image from 'next/image';
import { type Content } from '@/lib/types';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import { Button } from './ui/button';
import { Download, BookOpen, Headphones, Info } from 'lucide-react';
import { Badge } from './ui/badge';
import { useUser } from '@/hooks/use-user';
import { Alert, AlertDescription, AlertTitle } from './ui/alert';

export default function ContentCard({ content }: { content: Content }) {
  const { profile } = useUser();
  const isDemo = profile?.role === 'demo';

  return (
    <Dialog>
      <DialogTrigger asChild>
        <div className="group relative cursor-pointer overflow-hidden rounded-lg shadow-lg transition-transform duration-300 ease-in-out hover:-translate-y-2">
          <Image
            src={content.cover_url}
            alt={`Capa de ${content.title}`}
            width={300}
            height={450}
            className="h-full w-full object-cover"
            data-ai-hint="book cover"
          />
          <div className="absolute inset-0 bg-black/60 opacity-0 transition-opacity group-hover:opacity-100" />
          <div className="absolute inset-0 flex flex-col items-center justify-center p-4 text-center text-white opacity-0 transition-opacity group-hover:opacity-100">
            <h3 className="text-lg font-bold">{content.title}</h3>
            <p className="text-sm capitalize">{content.theme}</p>
          </div>
        </div>
      </DialogTrigger>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <div className="flex items-center gap-2">
            {content.type === 'book' ? <BookOpen className="h-5 w-5 text-primary" /> : <Headphones className="h-5 w-5 text-primary" />}
            <Badge variant="secondary" className="capitalize">{content.type === 'book' ? 'Livro' : 'Audiolivro'}</Badge>
            <Badge variant="outline" className="capitalize">{content.theme}</Badge>
          </div>
          <DialogTitle className="font-headline text-2xl pt-2">{content.title}</DialogTitle>
          <DialogDescription>
            {isDemo
              ? 'Esta é uma conta de demonstração. O download não está disponível.'
              : 'Faça o download do conteúdo para aproveitá-lo offline.'}
          </DialogDescription>
        </DialogHeader>
        <div className="py-4">
          <div className="relative mx-auto w-48 overflow-hidden rounded-md shadow-lg">
            <Image
              src={content.cover_url}
              alt={`Capa de ${content.title}`}
              width={200}
              height={300}
              className="h-full w-full object-cover"
              data-ai-hint="book cover"
            />
          </div>
        </div>
        {isDemo ? (
          <Alert>
            <Info className="h-4 w-4" />
            <AlertTitle>Função de Demonstração</AlertTitle>
            <AlertDescription>
              O download está desabilitado para este tipo de conta.
            </AlertDescription>
          </Alert>
        ) : (
          <a href={content.download_url} target="_blank" rel="noopener noreferrer">
            <Button className="w-full bg-accent text-accent-foreground hover:bg-accent/90">
              <Download className="mr-2 h-4 w-4" />
              Baixar
            </Button>
          </a>
        )}
      </DialogContent>
    </Dialog>
  );
}
