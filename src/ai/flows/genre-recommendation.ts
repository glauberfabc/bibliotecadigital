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
    .describe('The list of currently selected genres.'),
});
export type RecommendGenresInput = z.infer<typeof RecommendGenresInputSchema>;

const RecommendGenresOutputSchema = z.object({
  recommendedGenres: z
    .array(z.string())
    .describe('The list of recommended genres.'),
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
  prompt: `Based on the currently selected genres: {{currentGenres}},
  recommend other genres that the user might be interested in.  Only include genres related to books and audio books.
  Return a JSON array of strings representing the recommended genres.
  Do not include any of the currently selected genres in the returned array.
  Do not include any explanation text, only the JSON array.
  Example: ["Mystery", "Thriller", "Science Fiction"]`,
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
