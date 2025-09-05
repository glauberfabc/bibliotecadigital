'use client';

import { type ColumnDef } from '@tanstack/react-table';
import { type VideoLesson } from '@/lib/types';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuLabel, DropdownMenuSeparator, DropdownMenuTrigger } from '../ui/dropdown-menu';
import { Button } from '../ui/button';
import { MoreHorizontal } from 'lucide-react';
import { useState } from 'react';
import { useToast } from '@/hooks/use-toast';
import { deleteVideoLessonAction } from '@/app/admin/actions';
import VideoLessonFormDialog from './VideoLessonFormDialog';

const ActionCell = ({ lesson }: { lesson: VideoLesson }) => {
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false);
  const { toast } = useToast();

  const handleDelete = async () => {
    if (confirm(`Você tem certeza que quer deletar "${lesson.title}"?`)) {
      const result = await deleteVideoLessonAction(lesson.id);
      if (result.success) {
        toast({ title: 'Sucesso', description: 'Aula deletada com sucesso.' });
      } else {
        toast({ title: 'Erro', description: result.error, variant: 'destructive' });
      }
    }
  };

  return (
    <>
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="ghost" className="h-8 w-8 p-0">
            <span className="sr-only">Abrir menu</span>
            <MoreHorizontal className="h-4 w-4" />
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end">
          <DropdownMenuLabel>Ações</DropdownMenuLabel>
          <DropdownMenuItem onClick={() => setIsEditDialogOpen(true)}>
            Editar
          </DropdownMenuItem>
          <DropdownMenuSeparator />
          <DropdownMenuItem onClick={handleDelete} className="text-destructive focus:text-destructive">
            Deletar
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
      <VideoLessonFormDialog
        isOpen={isEditDialogOpen}
        setIsOpen={setIsEditDialogOpen}
        initialData={lesson}
      />
    </>
  );
}

export const columns: ColumnDef<VideoLesson>[] = [
  {
    accessorKey: 'title',
    header: 'Título',
  },
  {
    accessorKey: 'youtube_url',
    header: 'URL do YouTube',
    cell: ({ row }) => {
        const url = row.getValue('youtube_url') as string;
        return <a href={url} target="_blank" rel="noopener noreferrer" className="text-primary hover:underline">{url}</a>
    }
  },
  {
    accessorKey: 'created_at',
    header: 'Criado em',
    cell: ({ row }) => {
      const date = new Date(row.getValue('created_at'));
      return <span>{date.toLocaleDateString()}</span>;
    },
  },
  {
    id: 'actions',
    cell: ({ row }) => <ActionCell lesson={row.original} />,
  },
];
