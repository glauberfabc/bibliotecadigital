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
import GenreRecommender from './GenreRecommender';

function ContentGridInternal({ initialContents }: { initialContents: Content[] }) {
  const searchParams = useSearchParams();
  const initialTypeFilter = searchParams.get('type');
  
  const [contents] = useState<Content[]>(initialContents);
  const [searchTerm, setSearchTerm] = useState('');
  const [genreFilter, setGenreFilter] = useState('all');
  const [typeFilter, setTypeFilter] = useState(initialTypeFilter || 'all');

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
      
      <GenreRecommender currentGenres={genreFilter === 'all' ? [] : [genreFilter]} onGenreSelect={setGenreFilter}/>

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
