import { createServerClient } from '@/lib/supabase/server';
import { cookies } from 'next/headers';
import { type VideoLesson } from '@/lib/types';

function YouTubeEmbed({ url }: { url: string }) {
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
    <div className="aspect-video w-full overflow-hidden rounded-lg shadow-lg">
      <iframe
        width="100%"
        height="100%"
        src={`https://www.youtube.com/embed/${videoId}`}
        title="YouTube video player"
        frameBorder="0"
        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
        allowFullScreen
      ></iframe>
    </div>
  );
}

export default async function VideoLessonsPage() {
  const cookieStore = cookies();
  const supabase = createServerClient(cookieStore);

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
                <YouTubeEmbed url={lesson.youtube_url} />
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
