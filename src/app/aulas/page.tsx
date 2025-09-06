import { createServerClient } from '@/lib/supabase/server';
import { cookies } from 'next/headers';
import { type VideoLesson, type Profile } from '@/lib/types';
import { Info } from 'lucide-react';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';

function YouTubeEmbed({ url, isDemo }: { url: string, isDemo: boolean }) {
  const getYouTubeVideoId = (url: string) => {
    const regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*/;
    const match = url.match(regExp);
    return (match && match[2].length === 11) ? match[2] : null;
  };

  const videoId = getYouTubeVideoId(url);

  if (!videoId) {
    return <p className="text-destructive">URL do YouTube inválida.</p>;
  }
  
  return (
    <div className="relative aspect-video w-full overflow-hidden rounded-lg shadow-lg">
      <iframe
        width="100%"
        height="100%"
        src={`https://www.youtube.com/embed/${videoId}`}
        title="YouTube video player"
        frameBorder="0"
        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
        allowFullScreen
        className={isDemo ? 'pointer-events-none' : ''}
      ></iframe>
      {isDemo && (
         <div className="absolute inset-0 flex flex-col items-center justify-center bg-background/80 p-4 backdrop-blur-sm">
            <Alert className="max-w-md">
                <Info className="h-4 w-4" />
                <AlertTitle>Função de Demonstração</AlertTitle>
                <AlertDescription>
                A visualização de vídeos está desabilitada para este tipo de conta.
                </AlertDescription>
            </Alert>
         </div>
      )}
    </div>
  );
}

export default async function VideoLessonsPage() {
  const cookieStore = cookies();
  const supabase = createServerClient(cookieStore);

  const { data: { user } } = await supabase.auth.getUser();

  const { data: profile } = user
    ? await supabase.from('profiles').select('*').eq('id', user.id).single()
    : { data: null };
  
  const isDemo = (profile as Profile | null)?.role === 'demo';

  const { data: lessons, error } = await supabase
    .from('video_lessons')
    .select('*')
    .order('created_at', { ascending: true });

  if (error) {
    console.error('Error fetching video lessons:', error);
  }

  return (
    <main className="flex-1 px-4 py-8 md:px-6 lg:px-8">
      <div className="container mx-auto">
        <h1 className="mb-6 font-headline text-3xl font-bold tracking-tight text-foreground sm:text-4xl">
          Vídeo Aulas
        </h1>
        {lessons && lessons.length > 0 ? (
          <div className="grid grid-cols-1 gap-8 md:grid-cols-2 lg:grid-cols-3">
            {lessons.map((lesson: VideoLesson) => (
              <div key={lesson.id}>
                <YouTubeEmbed url={lesson.youtube_url} isDemo={isDemo} />
                <h2 className="mt-3 text-lg font-semibold">{lesson.title}</h2>
              </div>
            ))}
          </div>
        ) : (
          <div className="flex flex-col items-center justify-center rounded-lg border-2 border-dashed border-muted p-12 text-center">
            <h3 className="text-xl font-semibold tracking-tight">Nenhuma aula encontrada</h3>
            <p className="text-sm text-muted-foreground">
              Volte em breve para conferir as novidades.
            </p>
          </div>
        )}
      </div>
    </main>
  );
}
