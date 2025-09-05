export interface Content {
  id: string;
  title: string;
  theme: string;
  cover_url: string;
  type: 'book' | 'audiobook';
  download_url: string;
  created_at: string;
}

export interface Profile {
  id: string;
  email: string;
  role: 'admin' | 'user';
}

export interface VideoLesson {
  id: string;
  title: string;
  youtube_url: string;
  created_at: string;
}
