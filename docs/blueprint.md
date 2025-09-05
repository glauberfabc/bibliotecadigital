# **App Name**: Digital Library

## Core Features:

- User Authentication: Implement user login and registration using Supabase Auth with email/password.
- Content Display: Display books and audiobooks in a responsive grid layout. Authenticated users can view the covers, titles and download them. Content can be filtered by title or genre.
- Admin Dashboard: A protected dashboard accessible only to users with 'admin' role for managing content (create, edit, delete).
- Content Creation: Admin users can upload covers, add titles, specify theme and type (book/audiobook) and provide a download link for new content.
- Content Management: Admin users can view and manage a list of contents with options to exclude/edit entries.
- Role-Based Access Control: Enforce role-based access control via middleware that verifies if the logged-in user has the required role.
- Genre Recommendation: An AI tool recommends books of other genres based on currently displayed books or current filter selection.

## Style Guidelines:

- Primary color: Deep Indigo (#4B0082) for a sense of knowledge and sophistication.
- Background color: Very light grey (#F5F5F5), near white.
- Accent color: Gold (#FFD700) for highlighting important elements and CTAs.
- Body text: 'Inter' sans-serif for its modern, readable design. Headlines: 'Belleza' sans-serif to give titles personality.
- Use flat, modern icons for navigation and actions.
- Fixed header with logo and navigation. Responsive grid layout for content display. Use accessible components (modals, dropdowns).
- Subtle transitions and animations for feedback and visual engagement.