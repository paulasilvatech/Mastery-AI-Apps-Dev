import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import Heading from '@theme/Heading';
import Translate, {translate} from '@docusaurus/Translate';

import styles from './index.module.css';

function HomepageHeader() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <header className={clsx('hero hero--primary', styles.heroBanner)}>
      <div className="container">
        <Heading as="h1" className="hero__title">
          <Translate id="homepage.hero.title">Master AI Apps Development</Translate>
        </Heading>
        <p className="hero__subtitle">
          <Translate id="homepage.hero.subtitle">🚀 The Most Complete AI Development Workshop - 30 Modules, 90 Hands-on Exercises</Translate>
        </p>
        <div className={styles.buttons}>
          <Link
            className="button button--secondary button--lg"
            to="/docs/guias/quick-start">
            🚀 Build Your First AI App in 5 Minutes
          </Link>
        </div>
      </div>
    </header>
  );
}

function Feature({icon, title, description}) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center">
        <div className={styles.featureIcon}>{icon}</div>
      </div>
      <div className="text--center padding-horiz--md">
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

function HomepageFeatures() {
  const FeatureList = [
    {
      icon: '⚡',
      title: 'AI-Powered Development',
      description: 'Learn to leverage GitHub Copilot, ChatGPT, and Claude for 10x productivity gains in real-world projects.',
    },
    {
      icon: '🏗️',
      title: 'Enterprise Ready',
      description: 'From fundamentals to production deployment, covering microservices, cloud-native, and enterprise patterns.',
    },
    {
      icon: '🚀',
      title: '90 Practical Exercises',
      description: 'Each module includes 3 hands-on exercises (Easy, Medium, Hard) with step-by-step guidance.',
    },
  ];

  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}

function TrackSection() {
  const tracks = [
    {
      emoji: '🟢',
      title: 'Fundamentals Track',
      modules: '5 Modules',
      description: 'Master AI-assisted development basics',
      topics: ['GitHub Copilot', 'Prompt Engineering', 'AI Testing', 'Documentation'],
      link: '/docs/modules/module-01/',
    },
    {
      emoji: '🔵',
      title: 'Intermediate Development',
      modules: '5 Modules',
      description: 'Build real-world applications with AI',
      topics: ['API Development', 'Databases', 'Real-time Systems', 'AI Patterns'],
      link: '/docs/modules/module-06/',
    },
    {
      emoji: '🟠',
      title: 'Advanced Patterns',
      modules: '5 Modules',
      description: 'Enterprise architectures and DevOps',
      topics: ['Microservices', 'Cloud-Native', 'DevOps', 'Security'],
      link: '/docs/modules/module-11/',
    },
    {
      emoji: '🔴',
      title: 'Enterprise Solutions',
      modules: '5 Modules',
      description: 'Production-ready systems at scale',
      topics: ['System Integration', 'Event-Driven', 'Monitoring', 'Deployment'],
      link: '/docs/modules/module-16/',
    },
    {
      emoji: '🟣',
      title: 'AI Agents & MCP',
      modules: '5 Modules',
      description: 'Build intelligent autonomous agents',
      topics: ['AI Agents', 'Custom Agents', 'MCP Protocol', 'Orchestration'],
      link: '/docs/modules/module-21/',
    },
    {
      emoji: '⭐',
      title: 'Enterprise Mastery',
      modules: '5 Modules',
      description: 'Lead AI transformation initiatives',
      topics: ['Architecture', 'Legacy Modernization', 'Innovation', 'Certification'],
      link: '/docs/modules/module-26/',
    },
  ];

  return (
    <section className={styles.tracks}>
      <div className="container">
        <div className="text--center margin-bottom--xl">
          <Heading as="h2">📚 Learning Tracks</Heading>
          <p className={styles.sectionSubtitle}>
            Progressive curriculum designed for your success
          </p>
        </div>
        <div className={styles.trackGrid}>
          {tracks.map((track, idx) => (
            <div key={idx} className={styles.trackCard}>
              <div className={styles.trackHeader}>
                <span className={styles.trackEmoji}>{track.emoji}</span>
                <div>
                  <h3>{track.title}</h3>
                  <p className={styles.moduleCount}>{track.modules}</p>
                </div>
              </div>
              <p className={styles.trackDescription}>{track.description}</p>
              <div className={styles.trackTopics}>
                {track.topics.map((topic, i) => (
                  <span key={i} className={styles.topicTag}>{topic}</span>
                ))}
              </div>
              <Link to={track.link} className={styles.trackLink}>
                Explore Track →
              </Link>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function StatsSection() {
  return (
    <section className={styles.stats}>
      <div className="container">
        <div className={styles.statsGrid}>
          <div className={styles.statCard}>
            <div className={styles.statNumber}>30</div>
            <div className={styles.statLabel}>Comprehensive Modules</div>
          </div>
          <div className={styles.statCard}>
            <div className={styles.statNumber}>90</div>
            <div className={styles.statLabel}>Hands-on Exercises</div>
          </div>
          <div className={styles.statCard}>
            <div className={styles.statNumber}>180+</div>
            <div className={styles.statLabel}>Hours of Content</div>
          </div>
          <div className={styles.statCard}>
            <div className={styles.statNumber}>10x</div>
            <div className={styles.statLabel}>Productivity Boost</div>
          </div>
          <div className={styles.statCard}>
            <div className={styles.statNumber}>15+</div>
            <div className={styles.statLabel}>AI Tools Covered</div>
          </div>
          <div className={styles.statCard}>
            <div className={styles.statNumber}>100%</div>
            <div className={styles.statLabel}>Practical Focus</div>
          </div>
        </div>
      </div>
    </section>
  );
}

function AgenticDevOpsSection() {
  const concepts = [
    {
      icon: '🤖',
      title: 'Autonomous Agents',
      description: 'Build intelligent agents that can understand, plan, and execute development tasks autonomously, reducing manual intervention by 80%.',
      features: ['Self-healing systems', 'Automated code reviews', 'Intelligent debugging'],
    },
    {
      icon: '🔄',
      title: 'Continuous Intelligence',
      description: 'Implement AI-driven CI/CD pipelines that learn from every deployment, optimize performance, and predict potential issues.',
      features: ['Predictive analytics', 'Smart rollbacks', 'Performance optimization'],
    },
    {
      icon: '🛡️',
      title: 'Proactive Security',
      description: 'Deploy AI agents that continuously monitor, detect, and respond to security threats in real-time across your infrastructure.',
      features: ['Threat detection', 'Automated patching', 'Compliance monitoring'],
    },
  ];

  return (
    <section className={styles.agenticDevOps}>
      <div className="container">
        <div className="text--center margin-bottom--xl">
          <Heading as="h2">🚀 The Future: Agentic DevOps</Heading>
          <p className={styles.sectionSubtitle}>
            Transform your development workflow with AI agents that think, learn, and act autonomously
          </p>
        </div>
        <div className={styles.conceptGrid}>
          {concepts.map((concept, idx) => (
            <div key={idx} className={styles.conceptCard}>
              <div className={styles.conceptIcon}>{concept.icon}</div>
              <h3>{concept.title}</h3>
              <p className={styles.conceptDescription}>{concept.description}</p>
              <ul className={styles.featureList}>
                {concept.features.map((feature, i) => (
                  <li key={i}>{feature}</li>
                ))}
              </ul>
            </div>
          ))}
        </div>
        <div className="text--center margin-top--xl">
          <p className={styles.agenticCallout}>
            <strong>Learn to build these systems in our AI Agents modules (21-25)</strong>
          </p>
        </div>
      </div>
    </section>
  );
}

function CTASection() {
  return (
    <section className={styles.cta}>
      <div className="container">
        <div className={styles.ctaContent}>
          <Heading as="h2">🚀 Ready to Master AI Development?</Heading>
          <p className={styles.ctaSubtitle}>
            Join thousands of developers who are already building the future with AI
          </p>
          <div className={styles.ctaButtons}>
            <Link
              className="button button--primary button--lg"
              to="/docs/intro">
              Start Now
            </Link>
            <Link
              className="button button--outline button--secondary button--lg"
              to="/docs/guias/prerequisites">
              Check Prerequisites
            </Link>
          </div>
        </div>
      </div>
    </section>
  );
}

export default function Home() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout
      title={`Master AI Apps Development - The Complete Workshop`}
      description="Learn to build production-ready applications with AI. 30 modules, 90 exercises, from fundamentals to enterprise deployment.">
      <HomepageHeader />
      <main>
        <HomepageFeatures />
        <StatsSection />
        <TrackSection />
        <AgenticDevOpsSection />
        <CTASection />
      </main>
    </Layout>
  );
}