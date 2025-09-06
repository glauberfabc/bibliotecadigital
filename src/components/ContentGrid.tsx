'use client';

import { useState, useMemo, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import { type Content } from '@/lib/types';
import ContentCard from './ContentCard';
import { Input } from './ui/input';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { useUser } from '@/hooks/use-user';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Sparkles, ArrowRight } from 'lucide-react';
import Link from 'next/link';

function ContentGridInternal({ initialContents }: { initialContents: Content[] }) {
  const searchParams = useSearchParams();
  const initialTypeFilter = searchParams.get('type');
  
  const [contents] = useState<Content[]>(initialContents);
  const [searchTerm, setSearchTerm] = useState('');
  const [genreFilter, setGenreFilter] = useState('all');
  const [typeFilter, setTypeFilter] = useState(initialTypeFilter || 'all');
  const { profile } = useUser();

  const genres = useMemo(() => {
    const allGenres = new Set(contents.map((c) => c.theme));
    return ['all', ...Array.from(allGenres)];
  }, [contents]);

  const filteredContents = useMemo(() => {
    return contents.filter((content) => {
      const matchesSearch = content.title.toLowerCase().includes(searchTerm.toLowerCase());
      const matchesGenre = genreFilter === 'all' || content.theme === genreFilter;
      const matchesType = typeFilter === 'all' || content.type === typeFilter;
      return matchesSearch && matchesGenre && matchesType;
    });
  }, [contents, searchTerm, genreFilter, typeFilter]);

  return (
    <div>
      <div className="mb-8 grid grid-cols-1 gap-4 md:grid-cols-3">
        <Input
          placeholder="Buscar por título..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="md:col-span-1"
        />
        <Select value={genreFilter} onValueChange={setGenreFilter}>
          <SelectTrigger className="w-full">
            <SelectValue placeholder="Filtrar por gênero" />
          </SelectTrigger>
          <SelectContent>
            {genres.map((genre) => (
              <SelectItem key={genre} value={genre} className="capitalize">
                {genre === 'all' ? 'Todos os Gêneros' : genre}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select value={typeFilter} onValueChange={setTypeFilter}>
          <SelectTrigger className="w-full">
            <SelectValue placeholder="Filtrar por tipo" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Todos os Tipos</SelectItem>
            <SelectItem value="book">Livro</SelectItem>
            <SelectItem value="audiobook">Audiolivro</SelectItem>
          </SelectContent>
        </Select>
      </div>
      
      {profile?.role === 'demo' && (
        <div className="my-6">
            <Card className="border-2 border-accent bg-accent/10">
                <CardHeader className="items-center text-center">
                <div className="flex h-12 w-12 items-center justify-center rounded-full bg-accent text-accent-foreground">
                    <Sparkles className="h-6 w-6" />
                </div>
                <CardTitle className="font-headline text-2xl text-accent-foreground pt-2">
                    Oferta de Acesso Vitalício
                </CardTitle>
                <CardDescription className="text-foreground/80">
                    Desbloqueie downloads e vídeos ilimitados para sempre.
                </CardDescription>
                </CardHeader>
                <CardContent className="text-center">
                <p className="mb-4 text-sm text-muted-foreground">
                    Somente hoje, aproveite nossa oferta exclusiva:
                </p>
                <div className="mb-6">
                    <span className="text-4xl font-bold text-accent-foreground">R$37,90</span>
                    <span className="ml-2 text-lg text-muted-foreground line-through">R$97,00</span>
                </div>
                <Button asChild size="lg" className="w-full max-w-sm bg-accent text-accent-foreground hover:bg-accent/90 shadow-lg">
                    <Link href="https://flownetic-digital.mycartpanda.com/checkout/195590000:1">
                    Garantir Acesso Vitalício Agora
                    <ArrowRight className="ml-2 h-4 w-4" />
                    </Link>
                </Button>
                </CardContent>
            </Card>
        </div>
      )}

      {filteredContents.length > 0 ? (
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6">
          {filteredContents.map((content) => (
            <ContentCard key={content.id} content={content} />
          ))}
        </div>
      ) : (
        <div className="flex flex-col items-center justify-center rounded-lg border-2 border-dashed border-muted p-12 text-center">
          <h3 className="text-xl font-semibold tracking-tight">Nenhum conteúdo encontrado</h3>
          <p className="text-sm text-muted-foreground">
            Tente ajustar sua busca ou filtros.
          </p>
        </div>
      )}
    </div>
  );
}

export default function ContentGrid({ initialContents }: { initialContents: Content[] }) {
  return (
    <Suspense fallback={<div>Carregando filtros...</div>}>
      <ContentGridInternal initialContents={initialContents} />
    </Suspense>
  )
}
