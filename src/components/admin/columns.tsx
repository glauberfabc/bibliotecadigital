'use client';

import { type ColumnDef } from '@tanstack/react-table';
import { type Content } from '@/lib/types';
import Image from 'next/image';
import { Badge } from '../ui/badge';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuLabel, DropdownMenuSeparator, DropdownMenuTrigger } from '../ui/dropdown-menu';
import { Button } from '../ui/button';
import { MoreHorizontal } from 'lucide-react';
import ContentFormDialog from './ContentFormDialog';
import { useState } from 'react';
import { deleteContentAction } from '@/app/admin/actions';
import { useToast } from '@/hooks/use-toast';

const ActionCell = ({ content }: { content: Content }) => {
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false);
  const { toast } = useToast();

  const handleDelete = async () => {
    if (confirm(`Are you sure you want to delete "${content.title}"?`)) {
      const result = await deleteContentAction(content.id, content.cover_url);
      if (result.success) {
        toast({ title: 'Success', description: 'Content deleted successfully.' });
      } else {
        toast({ title: 'Error', description: result.error, variant: 'destructive' });
      }
    }
  };

  return (
    <>
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="ghost" className="h-8 w-8 p-0">
            <span className="sr-only">Open menu</span>
            <MoreHorizontal className="h-4 w-4" />
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end">
          <DropdownMenuLabel>Actions</DropdownMenuLabel>
          <DropdownMenuItem onClick={() => setIsEditDialogOpen(true)}>
            Edit
          </DropdownMenuItem>
          <DropdownMenuSeparator />
          <DropdownMenuItem onClick={handleDelete} className="text-destructive focus:text-destructive">
            Delete
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
      <ContentFormDialog
        isOpen={isEditDialogOpen}
        setIsOpen={setIsEditDialogOpen}
        initialData={content}
      />
    </>
  );
}

export const columns: ColumnDef<Content>[] = [
  {
    accessorKey: 'cover_url',
    header: 'Cover',
    cell: ({ row }) => {
      const url = row.getValue('cover_url') as string;
      const title = row.original.title;
      return (
        <Image
          src={url}
          alt={`Cover of ${title}`}
          width={40}
          height={60}
          className="rounded-sm object-cover"
          data-ai-hint="book cover"
        />
      );
    },
  },
  {
    accessorKey: 'title',
    header: 'Title',
  },
  {
    accessorKey: 'theme',
    header: 'Theme',
    cell: ({ row }) => <span className="capitalize">{row.getValue('theme')}</span>,
  },
  {
    accessorKey: 'type',
    header: 'Type',
    cell: ({ row }) => (
      <Badge variant="outline" className="capitalize">{row.getValue('type')}</Badge>
    ),
  },
  {
    accessorKey: 'created_at',
    header: 'Created At',
    cell: ({ row }) => {
      const date = new Date(row.getValue('created_at'));
      return <span>{date.toLocaleDateString()}</span>;
    },
  },
  {
    id: 'actions',
    cell: ({ row }) => <ActionCell content={row.original} />,
  },
];
