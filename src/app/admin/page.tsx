import { createServerClient } from '@/lib/supabase/server';
import { cookies } from 'next/headers';
import ContentDataTable from '@/components/admin/ContentDataTable';
import { columns as contentColumns } from '@/components/admin/columns';
import { type Content, type VideoLesson } from '@/lib/types';
import { redirect } from 'next/navigation';
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import VideoLessonDataTable from '@/components/admin/VideoLessonDataTable';
import { columns as videoLessonColumns } from '@/components/admin/videoLessonColumns';

export default async function AdminDashboard() {
  const cookieStore = cookies();
  const supabase = createServerClient(cookieStore);

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return redirect('/login');
  }

  const { data: contentsData, error: contentsError } = await supabase
    .from('contents')
    .select('*')
    .order('created_at', { ascending: false });

  if (contentsError) {
    console.error('Error fetching content for admin:', contentsError);
  }
  
  const contents: Content[] = contentsData || [];

  const { data: videoLessonsData, error: videoLessonsError } = await supabase
    .from('video_lessons')
    .select('*')
    .order('created_at', { ascending: false });
  
  if (videoLessonsError) {
    console.error('Error fetching video lessons for admin:', videoLessonsError);
  }

  const videoLessons: VideoLesson[] = videoLessonsData || [];

  return (
    <main className="flex-1 px-4 py-8 md:px-6 lg:px-8">
      <div className="container mx-auto">
        <div className="mb-6 flex items-center justify-between">
          <h1 className="font-headline text-3xl font-bold tracking-tight text-foreground sm:text-4xl">
            Gerenciamento
          </h1>
        </div>
        <Tabs defaultValue="content">
          <TabsList className="grid w-full grid-cols-2 md:w-1/3">
            <TabsTrigger value="content">Conteúdo</TabsTrigger>
            <TabsTrigger value="lessons">Vídeo Aulas</TabsTrigger>
          </TabsList>
          <TabsContent value="content">
            <ContentDataTable columns={contentColumns} data={contents} />
          </TabsContent>
          <TabsContent value="lessons">
            <VideoLessonDataTable columns={videoLessonColumns} data={videoLessons} />
          </TabsContent>
        </Tabs>
      </div>
    </main>
  );
}
