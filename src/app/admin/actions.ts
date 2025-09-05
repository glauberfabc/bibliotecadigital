'use server';

import { createServerClient } from '@/lib/supabase/server';
import { revalidatePath } from 'next/cache';
import { cookies } from 'next/headers';
import { z } from 'zod';
import { v4 as uuidv4 } from 'uuid';

const contentSchema = z.object({
  id: z.string().optional(),
  title: z.string().min(2),
  theme: z.string().min(1),
  type: z.enum(['book', 'audiobook']),
  download_url: z.string().url(),
});

export async function upsertContentAction(formData: FormData) {
  const cookieStore = cookies();
  const supabase = createServerClient(cookieStore);

  const rawFormData = Object.fromEntries(formData.entries());

  const validatedFields = contentSchema.safeParse(rawFormData);
  if (!validatedFields.success) {
    return { success: false, error: 'Invalid fields.' };
  }

  const { id, ...contentData } = validatedFields.data;
  const coverImage = formData.get('cover_image') as File | null;
  let cover_url = formData.get('existing_cover_url') as string | undefined;

  // Check user role
  const { data: { user } } = await supabase.auth.getUser();
  if(!user) return { success: false, error: 'Unauthorized' };
  const { data: profile } = await supabase.from('profiles').select('role').eq('id', user.id).single();
  if(profile?.role !== 'admin') return { success: false, error: 'Forbidden' };
  
  if (coverImage && coverImage.size > 0) {
    // If there's an existing image, delete it first
    if (id && cover_url) {
        const oldFilePath = new URL(cover_url).pathname.split('/covers/')[1];
        if (oldFilePath) {
            await supabase.storage.from('covers').remove([oldFilePath]);
        }
    }
    
    const filePath = `${user.id}/${uuidv4()}-${coverImage.name}`;
    const { data: uploadData, error: uploadError } = await supabase.storage
      .from('covers')
      .upload(filePath, coverImage);

    if (uploadError) {
      return { success: false, error: uploadError.message };
    }
    
    const { data: { publicUrl } } = supabase.storage.from('covers').getPublicUrl(uploadData.path);
    cover_url = publicUrl;
  }
  
  if (!cover_url) {
    return { success: false, error: 'Cover image is required.' };
  }
  
  const dataToUpsert = { ...contentData, cover_url };

  const query = id
    ? supabase.from('contents').update(dataToUpsert).eq('id', id)
    : supabase.from('contents').insert(dataToUpsert);

  const { error } = await query;

  if (error) {
    return { success: false, error: error.message };
  }

  revalidatePath('/admin');
  revalidatePath('/');
  return { success: true };
}


export async function deleteContentAction(id: string, cover_url: string) {
    const cookieStore = cookies();
    const supabase = createServerClient(cookieStore);

    // Check user role
    const { data: { user } } = await supabase.auth.getUser();
    if(!user) return { success: false, error: 'Unauthorized' };
    const { data: profile } = await supabase.from('profiles').select('role').eq('id', user.id).single();
    if(profile?.role !== 'admin') return { success: false, error: 'Forbidden' };

    // Delete storage object
    if (cover_url) {
        const filePath = new URL(cover_url).pathname.split('/covers/')[1];
        if (filePath) {
            const { error: storageError } = await supabase.storage.from('covers').remove([filePath]);
            if (storageError) {
                return { success: false, error: storageError.message };
            }
        }
    }

    // Delete database record
    const { error: dbError } = await supabase.from('contents').delete().eq('id', id);

    if (dbError) {
        return { success: false, error: dbError.message };
    }

    revalidatePath('/admin');
    revalidatePath('/');
    return { success: true };
}
