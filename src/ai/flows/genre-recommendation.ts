'use server';

/**
 * @fileOverview Provides genre recommendations based on the currently displayed books or filter selection.
 *
 * - recommendGenres - A function that recommends genres.
 * - RecommendGenresInput - The input type for the recommendGenres function.
 * - RecommendGenresOutput - The return type for the recommendGenres function.
 */

import {ai} from '@/ai/genkit';
import {z} from 'genkit';

const RecommendGenresInputSchema = z.object({
  currentGenres: z
    .array(z.string())
    .describe('A lista de gêneros selecionados atualmente.'),
});
export type RecommendGenresInput = z.infer<typeof RecommendGenresInputSchema>;

const RecommendGenresOutputSchema = z.object({
  recommendedGenres: z
    .array(z.string())
    .describe('A lista de gêneros recomendados.'),
});
export type RecommendGenresOutput = z.infer<typeof RecommendGenresOutputSchema>;

export async function recommendGenres(
  input: RecommendGenresInput
): Promise<RecommendGenresOutput> {
  return recommendGenresFlow(input);
}

const prompt = ai.definePrompt({
  name: 'recommendGenresPrompt',
  input: {schema: RecommendGenresInputSchema},
  output: {schema: RecommendGenresOutputSchema},
  prompt: `Com base nos gêneros selecionados atualmente: {{currentGenres}},
  recomende outros gêneros que o usuário possa se interessar. Inclua apenas gêneros relacionados a livros e audiolivros.
  Retorne um array JSON de strings representando os gêneros recomendados.
  Não inclua nenhum dos gêneros selecionados atualmente no array retornado.
  Não inclua nenhum texto explicativo, apenas o array JSON.
  Exemplo: ["Mistério", "Suspense", "Ficção Científica"]`,
});

const recommendGenresFlow = ai.defineFlow(
  {
    name: 'recommendGenresFlow',
    inputSchema: RecommendGenresInputSchema,
    outputSchema: RecommendGenresOutputSchema,
  },
  async input => {
    const {output} = await prompt(input);
    return output!;
  }
);
