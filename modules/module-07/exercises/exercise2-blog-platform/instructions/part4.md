# Exercise 2: Blog Platform with AI Features (Part 4)

## 📋 Step 4: Complete Frontend Implementation (30 minutes)

### 4.1 Authentication Components

Create `frontend/src/components/Auth/LoginForm.jsx`:

**Copilot Prompt Suggestion:**
```jsx
// Create a login form component that:
// - Uses React Hook Form for validation
// - Handles login with email/password
// - Shows loading state during submission
// - Redirects to dashboard on success
// - Displays error messages
// - Has link to register page
// Use Tailwind CSS for responsive design
```

**Expected Implementation:**
```jsx
import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { useNavigate, Link } from 'react-router-dom';
import { toast } from 'react-toastify';
import { api } from '../../services/api';
import { useAuth } from '../../contexts/AuthContext';

export default function LoginForm() {
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const { login } = useAuth();
  
  const {
    register,
    handleSubmit,
    formState: { errors }
  } = useForm();

  const onSubmit = async (data) => {
    setLoading(true);
    try {
      const formData = new FormData();
      formData.append('username', data.email);
      formData.append('password', data.password);
      
      const response = await api.post('/auth/login', formData);
      const { access_token } = response.data;
      
      login(access_token);
      toast.success('Welcome back!');
      navigate('/dashboard');
    } catch (error) {
      toast.error(error.response?.data?.detail || 'Login failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Sign in to your account
          </h2>
        </div>
        <form className="mt-8 space-y-6" onSubmit={handleSubmit(onSubmit)}>
          <div className="rounded-md shadow-sm -space-y-px">
            <div>
              <label htmlFor="email" className="sr-only">
                Email address
              </label>
              <input
                {...register('email', {
                  required: 'Email is required',
                  pattern: {
                    value: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i,
                    message: 'Invalid email address'
                  }
                })}
                type="email"
                autoComplete="email"
                className="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-t-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                placeholder="Email address"
              />
              {errors.email && (
                <p className="mt-1 text-sm text-red-600">{errors.email.message}</p>
              )}
            </div>
            <div>
              <label htmlFor="password" className="sr-only">
                Password
              </label>
              <input
                {...register('password', {
                  required: 'Password is required',
                  minLength: {
                    value: 6,
                    message: 'Password must be at least 6 characters'
                  }
                })}
                type="password"
                autoComplete="current-password"
                className="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-b-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                placeholder="Password"
              />
              {errors.password && (
                <p className="mt-1 text-sm text-red-600">{errors.password.message}</p>
              )}
            </div>
          </div>

          <div>
            <button
              type="submit"
              disabled={loading}
              className="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
            >
              {loading ? 'Signing in...' : 'Sign in'}
            </button>
          </div>

          <div className="text-center">
            <Link
              to="/register"
              className="font-medium text-indigo-600 hover:text-indigo-500"
            >
              Don't have an account? Sign up
            </Link>
          </div>
        </form>
      </div>
    </div>
  );
}
```

### 4.2 Rich Text Editor Component

Create `frontend/src/components/Editor/RichTextEditor.jsx`:

**Copilot Prompt Suggestion:**
```jsx
// Create a rich text editor component using react-quill that:
// - Supports formatting (bold, italic, headers, lists)
// - Allows image uploads with preview
// - Has AI content suggestion button
// - Validates content length
// - Auto-saves drafts to localStorage
// - Responsive toolbar for mobile
// Include custom toolbar configuration
```

**Expected Implementation:**
```jsx
import { useCallback, useRef, useState } from 'react';
import ReactQuill from 'react-quill';
import 'react-quill/dist/quill.snow.css';
import { toast } from 'react-toastify';
import { api } from '../../services/api';

const modules = {
  toolbar: {
    container: [
      [{ header: [1, 2, 3, false] }],
      ['bold', 'italic', 'underline', 'strike'],
      ['blockquote', 'code-block'],
      [{ list: 'ordered' }, { list: 'bullet' }],
      ['link', 'image'],
      ['clean'],
    ],
    handlers: {
      image: function() {
        const input = document.createElement('input');
        input.setAttribute('type', 'file');
        input.setAttribute('accept', 'image/*');
        input.click();

        input.onchange = async () => {
          const file = input.files[0];
          if (file) {
            const formData = new FormData();
            formData.append('file', file);

            try {
              const response = await api.post('/upload/image', formData);
              const imageUrl = response.data.url;
              
              const range = this.quill.getSelection();
              this.quill.insertEmbed(range.index, 'image', imageUrl);
            } catch (error) {
              toast.error('Failed to upload image');
            }
          }
        };
      },
    },
  },
};

export default function RichTextEditor({ value, onChange, placeholder }) {
  const [loading, setLoading] = useState(false);
  const quillRef = useRef(null);

  const handleAISuggestion = async () => {
    if (!value || value.length < 50) {
      toast.warning('Please write at least 50 characters for AI suggestions');
      return;
    }

    setLoading(true);
    try {
      const response = await api.post('/ai/suggest-content', {
        context: value,
        type: 'continuation'
      });
      
      const suggestion = response.data.suggestion;
      const editor = quillRef.current.getEditor();
      const range = editor.getSelection();
      
      if (range) {
        editor.insertText(range.index, '\n\n' + suggestion);
      } else {
        onChange(value + '\n\n' + suggestion);
      }
      
      toast.success('AI suggestion added!');
    } catch (error) {
      toast.error('Failed to get AI suggestion');
    } finally {
      setLoading(false);
    }
  };

  const handleChange = useCallback((content) => {
    onChange(content);
    // Auto-save to localStorage
    if (content.length > 10) {
      localStorage.setItem('draft-content', content);
    }
  }, [onChange]);

  return (
    <div className="relative">
      <div className="mb-2 flex justify-between items-center">
        <span className="text-sm text-gray-500">
          {value ? `${value.length} characters` : 'Start writing...'}
        </span>
        <button
          type="button"
          onClick={handleAISuggestion}
          disabled={loading}
          className="inline-flex items-center px-3 py-1 border border-transparent text-sm leading-4 font-medium rounded-md text-white bg-purple-600 hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 disabled:opacity-50"
        >
          {loading ? (
            <>
              <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
              </svg>
              Generating...
            </>
          ) : (
            <>✨ AI Suggestion</>
          )}
        </button>
      </div>
      
      <ReactQuill
        ref={quillRef}
        theme="snow"
        value={value}
        onChange={handleChange}
        placeholder={placeholder}
        modules={modules}
        className="bg-white"
      />
    </div>
  );
}
```

### 4.3 Blog Post Management

Create `frontend/src/pages/CreatePost.jsx`:

**Copilot Prompt Suggestion:**
```jsx
// Create a blog post creation page that:
// - Uses the RichTextEditor component
// - Handles title, excerpt, tags, featured image
// - Preview mode before publishing
// - Save as draft or publish
// - SEO metadata fields
// - Validates all inputs
// - Shows loading states
// Responsive layout with sidebar for post settings
```

**Expected Implementation:**
```jsx
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { toast } from 'react-toastify';
import RichTextEditor from '../components/Editor/RichTextEditor';
import ImageUpload from '../components/Common/ImageUpload';
import TagInput from '../components/Common/TagInput';
import { api } from '../services/api';

export default function CreatePost() {
  const [content, setContent] = useState('');
  const [featuredImage, setFeaturedImage] = useState('');
  const [tags, setTags] = useState([]);
  const [preview, setPreview] = useState(false);
  const [loading, setLoading] = useState(false);
  
  const navigate = useNavigate();
  const { register, handleSubmit, formState: { errors } } = useForm();

  const onSubmit = async (data, status = 'draft') => {
    if (!content || content.length < 100) {
      toast.error('Content must be at least 100 characters');
      return;
    }

    setLoading(true);
    try {
      const postData = {
        ...data,
        content,
        featured_image: featuredImage,
        tags,
        status
      };

      const response = await api.post('/posts', postData);
      toast.success(`Post ${status === 'published' ? 'published' : 'saved as draft'}!`);
      navigate(`/posts/${response.data.slug}`);
    } catch (error) {
      toast.error('Failed to create post');
    } finally {
      setLoading(false);
    }
  };

  const handlePublish = (data) => onSubmit(data, 'published');
  const handleDraft = (data) => onSubmit(data, 'draft');

  if (preview) {
    return (
      <div className="max-w-4xl mx-auto px-4 py-8">
        <div className="mb-4">
          <button
            onClick={() => setPreview(false)}
            className="text-indigo-600 hover:text-indigo-500"
          >
            ← Back to editing
          </button>
        </div>
        <article className="prose prose-lg max-w-none">
          {/* Preview content here */}
          <div dangerouslySetInnerHTML={{ __html: content }} />
        </article>
      </div>
    );
  }

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <form onSubmit={handleSubmit(handleDraft)}>
        <div className="lg:grid lg:grid-cols-3 lg:gap-8">
          {/* Main Content Area */}
          <div className="lg:col-span-2">
            <div className="bg-white shadow rounded-lg p-6">
              <h1 className="text-2xl font-bold text-gray-900 mb-6">
                Create New Post
              </h1>

              {/* Title */}
              <div className="mb-6">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Title
                </label>
                <input
                  {...register('title', {
                    required: 'Title is required',
                    minLength: {
                      value: 5,
                      message: 'Title must be at least 5 characters'
                    }
                  })}
                  type="text"
                  className="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                  placeholder="Enter your post title"
                />
                {errors.title && (
                  <p className="mt-1 text-sm text-red-600">{errors.title.message}</p>
                )}
              </div>

              {/* Excerpt */}
              <div className="mb-6">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Excerpt
                </label>
                <textarea
                  {...register('excerpt', {
                    required: 'Excerpt is required',
                    maxLength: {
                      value: 200,
                      message: 'Excerpt must be less than 200 characters'
                    }
                  })}
                  rows={3}
                  className="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                  placeholder="Brief description of your post"
                />
                {errors.excerpt && (
                  <p className="mt-1 text-sm text-red-600">{errors.excerpt.message}</p>
                )}
              </div>

              {/* Content Editor */}
              <div className="mb-6">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Content
                </label>
                <RichTextEditor
                  value={content}
                  onChange={setContent}
                  placeholder="Start writing your post..."
                />
              </div>
            </div>
          </div>

          {/* Sidebar */}
          <div className="mt-8 lg:mt-0">
            <div className="bg-white shadow rounded-lg p-6 space-y-6">
              {/* Featured Image */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Featured Image
                </label>
                <ImageUpload
                  value={featuredImage}
                  onChange={setFeaturedImage}
                  placeholder="Upload featured image"
                />
              </div>

              {/* Tags */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Tags
                </label>
                <TagInput
                  value={tags}
                  onChange={setTags}
                  placeholder="Add tags..."
                />
              </div>

              {/* SEO Settings */}
              <div>
                <h3 className="text-sm font-medium text-gray-700 mb-3">
                  SEO Settings
                </h3>
                <div className="space-y-3">
                  <input
                    {...register('meta_title')}
                    type="text"
                    placeholder="Meta title"
                    className="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                  />
                  <textarea
                    {...register('meta_description')}
                    rows={2}
                    placeholder="Meta description"
                    className="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                  />
                </div>
              </div>

              {/* Actions */}
              <div className="space-y-3">
                <button
                  type="button"
                  onClick={() => setPreview(true)}
                  className="w-full inline-flex justify-center items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
                >
                  Preview
                </button>
                
                <button
                  type="submit"
                  disabled={loading}
                  className="w-full inline-flex justify-center items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-gray-600 hover:bg-gray-700"
                >
                  Save as Draft
                </button>
                
                <button
                  type="button"
                  onClick={handleSubmit(handlePublish)}
                  disabled={loading}
                  className="w-full inline-flex justify-center items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
                >
                  {loading ? 'Publishing...' : 'Publish'}
                </button>
              </div>
            </div>
          </div>
        </div>
      </form>
    </div>
  );
}
```

### 4.4 Comment System

Create `frontend/src/components/Comments/CommentSection.jsx`:

**Copilot Prompt Suggestion:**
```jsx
// Create a comment section component that:
// - Shows nested comments (replies)
// - Allows authenticated users to comment
// - Has moderation controls for admins
// - Real-time comment updates
// - Pagination for many comments
// - Like/dislike functionality
// - Report inappropriate comments
// Mobile-friendly threaded design
```

**Expected Implementation:**
```jsx
import { useState, useEffect } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { api } from '../../services/api';
import { toast } from 'react-toastify';
import { formatDistanceToNow } from 'date-fns';

export default function CommentSection({ postId }) {
  const [comments, setComments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [newComment, setNewComment] = useState('');
  const [replyTo, setReplyTo] = useState(null);
  const [submitting, setSubmitting] = useState(false);
  
  const { user, isAuthenticated } = useAuth();

  useEffect(() => {
    fetchComments();
  }, [postId]);

  const fetchComments = async () => {
    try {
      const response = await api.get(`/posts/${postId}/comments`);
      setComments(response.data);
    } catch (error) {
      toast.error('Failed to load comments');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!newComment.trim()) return;

    setSubmitting(true);
    try {
      const response = await api.post('/comments', {
        post_id: postId,
        content: newComment,
        parent_id: replyTo?.id
      });

      if (replyTo) {
        // Add reply to parent comment
        setComments(comments.map(comment => 
          comment.id === replyTo.id
            ? { ...comment, replies: [...(comment.replies || []), response.data] }
            : comment
        ));
      } else {
        // Add new top-level comment
        setComments([response.data, ...comments]);
      }

      setNewComment('');
      setReplyTo(null);
      toast.success('Comment posted!');
    } catch (error) {
      toast.error('Failed to post comment');
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async (commentId) => {
    if (!confirm('Are you sure you want to delete this comment?')) return;

    try {
      await api.delete(`/comments/${commentId}`);
      setComments(comments.filter(c => c.id !== commentId));
      toast.success('Comment deleted');
    } catch (error) {
      toast.error('Failed to delete comment');
    }
  };

  const CommentItem = ({ comment, isReply = false }) => (
    <div className={`${isReply ? 'ml-8' : ''} mb-4`}>
      <div className="bg-white rounded-lg shadow-sm p-4">
        <div className="flex items-start justify-between">
          <div className="flex items-center">
            <div className="h-10 w-10 rounded-full bg-indigo-500 flex items-center justify-center text-white font-medium">
              {comment.author.username[0].toUpperCase()}
            </div>
            <div className="ml-3">
              <p className="text-sm font-medium text-gray-900">
                {comment.author.username}
              </p>
              <p className="text-xs text-gray-500">
                {formatDistanceToNow(new Date(comment.created_at), { addSuffix: true })}
              </p>
            </div>
          </div>
          
          {(user?.id === comment.author.id || user?.is_admin) && (
            <button
              onClick={() => handleDelete(comment.id)}
              className="text-gray-400 hover:text-red-600"
            >
              <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
            </button>
          )}
        </div>
        
        <div className="mt-3">
          <p className="text-gray-700">{comment.content}</p>
        </div>
        
        <div className="mt-3 flex items-center space-x-4">
          <button
            onClick={() => setReplyTo(comment)}
            className="text-sm text-indigo-600 hover:text-indigo-500"
          >
            Reply
          </button>
        </div>
      </div>
      
      {/* Render replies */}
      {comment.replies?.map(reply => (
        <CommentItem key={reply.id} comment={reply} isReply />
      ))}
    </div>
  );

  if (loading) {
    return (
      <div className="flex justify-center py-8">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  return (
    <div className="mt-8">
      <h3 className="text-lg font-medium text-gray-900 mb-4">
        Comments ({comments.length})
      </h3>

      {/* Comment Form */}
      {isAuthenticated ? (
        <form onSubmit={handleSubmit} className="mb-8">
          {replyTo && (
            <div className="mb-2 p-2 bg-gray-100 rounded flex items-center justify-between">
              <span className="text-sm text-gray-600">
                Replying to {replyTo.author.username}
              </span>
              <button
                type="button"
                onClick={() => setReplyTo(null)}
                className="text-gray-400 hover:text-gray-600"
              >
                ×
              </button>
            </div>
          )}
          
          <div className="flex space-x-3">
            <div className="h-10 w-10 rounded-full bg-indigo-500 flex items-center justify-center text-white font-medium flex-shrink-0">
              {user.username[0].toUpperCase()}
            </div>
            <div className="flex-1">
              <textarea
                value={newComment}
                onChange={(e) => setNewComment(e.target.value)}
                rows={3}
                className="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                placeholder="Write a comment..."
              />
              <div className="mt-3 flex justify-end">
                <button
                  type="submit"
                  disabled={submitting || !newComment.trim()}
                  className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
                >
                  {submitting ? 'Posting...' : 'Post Comment'}
                </button>
              </div>
            </div>
          </div>
        </form>
      ) : (
        <div className="mb-8 p-4 bg-gray-50 rounded-lg text-center">
          <p className="text-gray-600">
            Please <Link to="/login" className="text-indigo-600 hover:text-indigo-500">sign in</Link> to comment.
          </p>
        </div>
      )}

      {/* Comments List */}
      <div className="space-y-4">
        {comments.length > 0 ? (
          comments.map(comment => (
            <CommentItem key={comment.id} comment={comment} />
          ))
        ) : (
          <p className="text-gray-500 text-center py-8">
            No comments yet. Be the first to comment!
          </p>
        )}
      </div>
    </div>
  );
}
```

## ✅ Checkpoint 4

Before proceeding to deployment:
- [ ] Authentication flow working (login/register)
- [ ] Rich text editor with AI suggestions
- [ ] Blog post creation and editing
- [ ] Comment system functional
- [ ] Image uploads working
- [ ] SEO metadata handled
- [ ] Responsive design verified
- [ ] No console errors

### Test the Complete Application

1. **Start both servers:**
   ```bash
   # Terminal 1 - Backend
   cd backend
   python run.py

   # Terminal 2 - Frontend
   cd frontend
   npm run dev
   ```

2. **Test user flow:**
   - Register a new account
   - Create a blog post with AI suggestions
   - Upload a featured image
   - Publish the post
   - Add comments
   - Edit the post

3. **Verify features:**
   - Authentication persists on refresh
   - Draft auto-save works
   - Comments update in real-time
   - Images upload correctly
   - SEO metadata is saved

## 🚀 Bonus Features

If you finish early, try implementing:

1. **Social Sharing**
   ```jsx
   // Add social share buttons for posts
   // Twitter, LinkedIn, Facebook
   // Copy link functionality
   ```

2. **Analytics Dashboard**
   ```jsx
   // View count charts
   // Popular posts
   // Comment engagement metrics
   ```

3. **Email Notifications**
   ```python
   # Send email when:
   # - New comment on your post
   # - Someone replies to your comment
   # - Admin approves your comment
   ```

## 🎯 Final Integration

### Deploy to Production

1. **Backend Deployment (Render/Railway):**
   ```dockerfile
   FROM python:3.11-slim
   WORKDIR /app
   COPY requirements.txt .
   RUN pip install -r requirements.txt
   COPY . .
   CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
   ```

2. **Frontend Deployment (Vercel/Netlify):**
   ```bash
   npm run build
   # Deploy dist/ folder
   ```

3. **Environment Variables:**
   - Set production database URL
   - Configure CORS for production domain
   - Set secure JWT secret
   - Configure file storage (S3/Cloudinary)

## 🎉 Congratulations!

You've successfully built a full-featured blog platform with:
- 🔐 Secure authentication system
- 📝 Rich text editing with AI assistance
- 💬 Interactive comment system
- 🖼️ Image management
- 🔍 SEO optimization
- 📱 Responsive design

### What You've Learned
- Building complex full-stack applications
- Implementing authentication flows
- Managing file uploads
- Creating real-time features
- Using AI for content generation
- Deploying production applications

### Next Steps
- Add more AI features (content recommendations, auto-tagging)
- Implement advanced search with filters
- Add user profiles and following system
- Create mobile app with React Native
- Integrate with external services (social media, analytics)

## 🆘 Troubleshooting

**Common Issues:**

1. **AI suggestions not working:**
   - Check OpenAI API key is set
   - Verify endpoint URL is correct
   - Check network requests in browser

2. **Image upload fails:**
   - Ensure upload directory exists
   - Check file size limits
   - Verify MIME type validation

3. **Comments not updating:**
   - Check WebSocket connection
   - Verify authentication token
   - Look for console errors

For more help, refer to the module troubleshooting guide or post in the discussion forum.

---

## 🔗 Navigation

[← Previous: Part 3](part3.md) | [🏠 Module Home](../../../README.md) | [Next Exercise →](../../exercise3-ai-dashboard/README.md)

## 📚 Quick Links

- [Prerequisites](../../../prerequisites.md)
- [Module Resources](../../../README.md#resources)
- [Troubleshooting Guide](../../../troubleshooting.md)
- [Solution Code](../solution/)

