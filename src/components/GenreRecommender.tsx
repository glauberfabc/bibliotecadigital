'use client';

import { useState, useTransition } from 'react';
import { recommendGenres } from '@/ai/flows/genre-recommendation';
import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { Wand2, Loader2 } from 'lucide-react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';

type GenreRecommenderProps = {
  currentGenres: string[];
  onGenreSelect: (genre: string) => void;
};

export default function GenreRecommender({ currentGenres, onGenreSelect }: GenreRecommenderProps) {
  const [isPending, startTransition] = useTransition();
  const [recommendations, setRecommendations] = useState<string[]>([]);
  const [error, setError] = useState<string | null>(null);

  const handleRecommendation = () => {
    startTransition(async () => {
      setError(null);
      setRecommendations([]);
      try {
        const result = await recommendGenres({ currentGenres });
        setRecommendations(result.recommendedGenres);
      } catch (e) {
        setError('Could not fetch recommendations. Please try again.');
        console.error(e);
      }
    });
  };

  return (
    <div className="my-6">
      <Card className="bg-card/50">
        <CardHeader>
          <CardTitle className="flex items-center gap-2 font-headline text-xl">
            <Wand2 className="h-5 w-5 text-accent" />
            Need a suggestion?
          </CardTitle>
          <CardDescription>
            {currentGenres.length > 0
              ? `Based on your interest in ${currentGenres.join(', ')}, let our AI recommend some other genres you might like.`
              : 'Let our AI recommend some genres for you to explore.'}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Button onClick={handleRecommendation} disabled={isPending} className="bg-accent text-accent-foreground hover:bg-accent/90">
            {isPending ? (
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
            ) : (
              <Wand2 className="mr-2 h-4 w-4" />
            )}
            Get Recommendations
          </Button>

          {isPending && (
            <div className="mt-4 text-sm text-muted-foreground">
              Thinking...
            </div>
          )}

          {error && <p className="mt-4 text-sm text-destructive">{error}</p>}
          
          {recommendations.length > 0 && (
            <div className="mt-4">
              <p className="mb-2 text-sm font-medium">How about these?</p>
              <div className="flex flex-wrap gap-2">
                {recommendations.map((genre) => (
                  <Badge
                    key={genre}
                    variant="secondary"
                    onClick={() => onGenreSelect(genre)}
                    className="cursor-pointer transition-colors hover:bg-primary hover:text-primary-foreground"
                  >
                    {genre}
                  </Badge>
                ))}
              </div>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
