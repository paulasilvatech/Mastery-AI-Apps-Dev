# Exercise 2: Modern Blog Platform

## 📋 Overview

Create a feature-rich blog platform with content management, user authentication, and advanced features. This exercise builds upon the skills from Exercise 1, introducing more complex state management, advanced database relationships, and production-grade features.

## 🎯 Learning Objectives

By completing this exercise, you will:

- ✅ Design complex database schemas with relationships
- ✅ Implement advanced authentication (OAuth, roles)
- ✅ Build a rich text editor with image uploads
- ✅ Create SEO-friendly server-side rendering
- ✅ Implement caching strategies
- ✅ Add real-time features (comments, likes)
- ✅ Configure CDN and media storage
- ✅ Deploy with auto-scaling capabilities

## 📁 Structure

```
exercise2-blog-platform/
├── README.md                    # This file
├── instructions/                # Detailed guides
│   ├── part1.md                # Core blog features
│   ├── part2.md                # Advanced features
│   ├── part3.md                # Performance & SEO
│   └── part4.md                # Deployment & scaling
├── starter/                     # Starting templates
│   ├── backend/                # API starter
│   │   ├── src/
│   │   ├── prisma/            # Database schema
│   │   └── package.json
│   ├── frontend/              # Next.js starter
│   │   ├── pages/            # Page components
│   │   ├── components/       # Reusable components
│   │   └── package.json
│   └── infrastructure/        # IaC templates
├── solution/                   # Complete implementation
│   ├── backend/               # Full API solution
│   │   ├── src/
│   │   │   ├── auth/         # Authentication
│   │   │   ├── posts/        # Blog posts
│   │   │   ├── users/        # User management
│   │   │   ├── comments/     # Comments system
│   │   │   ├── media/        # File uploads
│   │   │   └── search/       # Search functionality
│   │   └── tests/
│   ├── frontend/             # Full frontend
│   │   ├── pages/
│   │   ├── components/
│   │   ├── hooks/
│   │   ├── services/
│   │   └── styles/
│   └── deployment/           # Production configs
│       ├── docker/
│       ├── kubernetes/
│       └── terraform/
├── tests/                     # Testing suite
│   ├── e2e/                  # End-to-end tests
│   ├── integration/          # Integration tests
│   └── performance/          # Load tests
└── troubleshooting.md        # Common issues
```

## 🚀 Getting Started

### Prerequisites

1. **Development Environment**:
   - Node.js 18.x+
   - PostgreSQL 14+
   - Redis 7+
   - Docker & Docker Compose

2. **Cloud Accounts**:
   - Azure/AWS account
   - Cloudinary/S3 for media
   - SendGrid/SES for emails

3. **Development Tools**:
   ```bash
   # Install global tools
   npm install -g @nestjs/cli prisma vercel
   ```

### Quick Start

1. **Initialize the project**:
   ```bash
   cd exercise2-blog-platform
   ./scripts/setup.sh
   ```

2. **Configure environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your credentials
   ```

3. **Start development servers**:
   ```bash
   # Terminal 1: Backend
   cd backend && npm run dev

   # Terminal 2: Frontend
   cd frontend && npm run dev

   # Terminal 3: Database & Redis
   docker-compose up -d
   ```

4. **Access the application**:
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:4000
   - Swagger Docs: http://localhost:4000/api
   - Prisma Studio: http://localhost:5555

## 📚 Exercise Parts

### Part 1: Core Blog Features (2 hours)
- User registration and authentication
- Create, edit, delete posts
- Rich text editor integration
- Categories and tags
- Basic commenting system

### Part 2: Advanced Features (2 hours)
- OAuth integration (Google, GitHub)
- Role-based access control
- Image upload with optimization
- Search functionality
- Email notifications

### Part 3: Performance & SEO (1.5 hours)
- Server-side rendering setup
- Implement caching layers
- SEO meta tags
- Sitemap generation
- Performance optimization

### Part 4: Deployment & Scaling (1.5 hours)
- Containerize applications
- Set up CI/CD pipeline
- Configure auto-scaling
- Implement monitoring
- Set up CDN

## 🎨 Features to Implement

### Core Features
- 📝 **Content Management**
  - Create/Edit/Delete posts
  - Draft and publish states
  - Rich text editor (Quill/TinyMCE)
  - Markdown support
  - Code syntax highlighting

- 👤 **User System**
  - Registration with email verification
  - Login (JWT + refresh tokens)
  - User profiles
  - Author pages
  - Password reset

- 💬 **Engagement**
  - Nested comments
  - Like/bookmark posts
  - Share functionality
  - RSS feed
  - Newsletter subscription

### Advanced Features
- 🔍 **Search & Discovery**
  - Full-text search
  - Filter by category/tag/author
  - Related posts
  - Popular posts
  - Reading time estimation

- 📊 **Analytics**
  - View counts
  - Reading statistics
  - Popular content dashboard
  - User engagement metrics

- 🚀 **Performance**
  - Lazy loading images
  - Infinite scroll
  - Progressive Web App
  - Offline reading
  - Image optimization

## 🏗️ Technical Architecture

### Backend Stack
- **Framework**: NestJS (TypeScript)
- **Database**: PostgreSQL with Prisma ORM
- **Cache**: Redis
- **Authentication**: Passport.js
- **File Storage**: AWS S3 / Azure Blob
- **Email**: SendGrid / AWS SES
- **Search**: PostgreSQL Full-Text / Elasticsearch

### Frontend Stack
- **Framework**: Next.js 14
- **Language**: TypeScript
- **Styling**: Tailwind CSS + shadcn/ui
- **State**: Zustand / TanStack Query
- **Editor**: TipTap / Lexical
- **Forms**: React Hook Form + Zod
- **SEO**: Next SEO

### Infrastructure
- **Containers**: Docker
- **Orchestration**: Kubernetes / Docker Swarm
- **CI/CD**: GitHub Actions
- **Monitoring**: Datadog / New Relic
- **CDN**: Cloudflare / Azure CDN
- **Database**: Managed PostgreSQL

## 📊 Database Schema

```prisma
model User {
  id        String   @id @default(cuid())
  email     String   @unique
  name      String
  bio       String?
  avatar    String?
  role      Role     @default(USER)
  posts     Post[]
  comments  Comment[]
  likes     Like[]
  createdAt DateTime @default(now())
}

model Post {
  id          String    @id @default(cuid())
  title       String
  slug        String    @unique
  content     String
  excerpt     String?
  coverImage  String?
  published   Boolean   @default(false)
  author      User      @relation(...)
  categories  Category[]
  tags        Tag[]
  comments    Comment[]
  likes       Like[]
  views       Int       @default(0)
  publishedAt DateTime?
  createdAt   DateTime  @default(now())
  updatedAt   DateTime  @updatedAt
}

// Additional models: Category, Tag, Comment, Like, etc.
```

## 📈 Performance Requirements

- **Page Load**: < 3s on 3G
- **API Response**: < 200ms average
- **Lighthouse Score**: > 90
- **Uptime**: 99.9%
- **Concurrent Users**: 1000+

## 🛠️ Troubleshooting

### Common Issues

1. **Database Connection**:
   ```bash
   # Reset database
   npx prisma migrate reset
   
   # Check connection
   npx prisma db pull
   ```

2. **Redis Connection**:
   ```bash
   # Test Redis
   redis-cli ping
   
   # Clear cache
   redis-cli FLUSHALL
   ```

3. **Build Errors**:
   ```bash
   # Clear Next.js cache
   rm -rf .next
   
   # Reinstall dependencies
   rm -rf node_modules package-lock.json
   npm install
   ```

## 🏆 Bonus Challenges

1. **AI Features**: Auto-tagging, content suggestions
2. **Multilingual**: i18n support
3. **Monetization**: Paywall, subscriptions
4. **Mobile App**: React Native companion
5. **GraphQL**: Alternative API

## 📖 Resources

- 📚 [Next.js Documentation](https://nextjs.org/docs)
- 🏗️ [NestJS Documentation](https://docs.nestjs.com/)
- 🗄️ [Prisma Documentation](https://www.prisma.io/docs/)
- 🎨 [Tailwind CSS](https://tailwindcss.com/)
- 🚀 [Vercel Deployment](https://vercel.com/docs)

## 🤝 Need Help?

1. Review the solution code
2. Check error logs carefully
3. Use debugging tools
4. Ask in the course forum

## ⏭️ Next Steps

After completing this exercise:
1. Add more advanced features
2. Optimize for production
3. Move to [Exercise 3: AI Dashboard](../exercise3-ai-dashboard/)
4. Deploy with custom domain

---

**Remember**: A great blog platform balances features with performance. Start simple, test thoroughly, and iterate based on user feedback! 📝✨
