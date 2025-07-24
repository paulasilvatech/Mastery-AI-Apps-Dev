#!/usr/bin/env node

/**
 * Prepare translation structure for Docusaurus i18n
 * This script creates the necessary files and folders for translations
 */

const fs = require('fs');
const path = require('path');

// Basic translations for UI elements
const translations = {
  'pt-BR': {
    navbar: {
      "title": {
        "message": "Workshop IA Maestria",
        "description": "The title in the navbar"
      },
      "item.label.Documentation": {
        "message": "Documentação",
        "description": "Navbar item with label Documentation"
      },
      "item.label.Start Learning": {
        "message": "Começar a Aprender",
        "description": "Navbar item with label Start Learning"
      },
      "item.label.GitHub": {
        "message": "GitHub",
        "description": "Navbar item with label GitHub"
      }
    },
    footer: {
      "link.title.Workshop": {
        "message": "Workshop",
        "description": "The title of the footer links column with title=Workshop"
      },
      "link.item.label.Get Started": {
        "message": "Começar",
        "description": "The label of footer link with label=Get Started"
      },
      "link.item.label.Prerequisites": {
        "message": "Pré-requisitos",
        "description": "The label of footer link with label=Prerequisites"
      },
      "link.title.Community": {
        "message": "Comunidade",
        "description": "The title of the footer links column with title=Community"
      },
      "link.item.label.Discussions": {
        "message": "Discussões",
        "description": "The label of footer link with label=Discussions"
      },
      "link.title.More": {
        "message": "Mais",
        "description": "The title of the footer links column with title=More"
      },
      "copyright": {
        "message": "Copyright © 2025 Paula Silva Tech. Desenvolvido por <a href=\"https://github.com/paulasilvatech\" target=\"_blank\">@paulasilvatech</a>. Feito com Docusaurus.",
        "description": "The footer copyright"
      }
    },
    homepage: {
      "hero.title": "Domine o Desenvolvimento de Apps com IA",
      "hero.subtitle": "🚀 O Workshop Mais Completo de Desenvolvimento com IA - 30 Módulos, 90 Exercícios Práticos",
      "hero.button": "🚀 Construa Seu Primeiro App IA em 5 Minutos",
      "features.ai.title": "Desenvolvimento com IA",
      "features.ai.description": "Aprenda a usar GitHub Copilot, ChatGPT e Claude para ganhos de produtividade de 10x em projetos reais.",
      "features.enterprise.title": "Pronto para Empresas",
      "features.enterprise.description": "Dos fundamentos ao deployment em produção, cobrindo microsserviços, cloud-native e padrões enterprise.",
      "features.exercises.title": "90 Exercícios Práticos",
      "features.exercises.description": "Cada módulo inclui 3 exercícios práticos (Fácil, Médio, Difícil) com orientação passo a passo.",
      "stats.modules": "Módulos Completos",
      "stats.exercises": "Exercícios Práticos",
      "stats.hours": "Horas de Conteúdo",
      "stats.productivity": "Aumento de Produtividade",
      "stats.tools": "Ferramentas IA Cobertas",
      "stats.practical": "Foco Prático",
      "tracks.title": "📚 Trilhas de Aprendizado",
      "tracks.subtitle": "Currículo progressivo projetado para seu sucesso",
      "cta.title": "🚀 Pronto para Dominar o Desenvolvimento com IA?",
      "cta.subtitle": "Junte-se a milhares de desenvolvedores que já estão construindo o futuro com IA",
      "cta.start": "Começar Agora",
      "cta.prerequisites": "Verificar Pré-requisitos"
    }
  },
  'es': {
    navbar: {
      "title": {
        "message": "Taller IA Maestría",
        "description": "The title in the navbar"
      },
      "item.label.Documentation": {
        "message": "Documentación",
        "description": "Navbar item with label Documentation"
      },
      "item.label.Start Learning": {
        "message": "Empezar a Aprender",
        "description": "Navbar item with label Start Learning"
      },
      "item.label.GitHub": {
        "message": "GitHub",
        "description": "Navbar item with label GitHub"
      }
    },
    footer: {
      "link.title.Workshop": {
        "message": "Taller",
        "description": "The title of the footer links column with title=Workshop"
      },
      "link.item.label.Get Started": {
        "message": "Empezar",
        "description": "The label of footer link with label=Get Started"
      },
      "link.item.label.Prerequisites": {
        "message": "Prerrequisitos",
        "description": "The label of footer link with label=Prerequisites"
      },
      "link.title.Community": {
        "message": "Comunidad",
        "description": "The title of the footer links column with title=Community"
      },
      "link.item.label.Discussions": {
        "message": "Discusiones",
        "description": "The label of footer link with label=Discussions"
      },
      "link.title.More": {
        "message": "Más",
        "description": "The title of the footer links column with title=More"
      },
      "copyright": {
        "message": "Copyright © 2025 Paula Silva Tech. Desarrollado por <a href=\"https://github.com/paulasilvatech\" target=\"_blank\">@paulasilvatech</a>. Hecho con Docusaurus.",
        "description": "The footer copyright"
      }
    },
    homepage: {
      "hero.title": "Domina el Desarrollo de Apps con IA",
      "hero.subtitle": "🚀 El Taller Más Completo de Desarrollo con IA - 30 Módulos, 90 Ejercicios Prácticos",
      "hero.button": "🚀 Construye Tu Primera App IA en 5 Minutos",
      "features.ai.title": "Desarrollo con IA",
      "features.ai.description": "Aprende a usar GitHub Copilot, ChatGPT y Claude para ganancias de productividad de 10x en proyectos reales.",
      "features.enterprise.title": "Listo para Empresas",
      "features.enterprise.description": "Desde los fundamentos hasta el despliegue en producción, cubriendo microservicios, cloud-native y patrones enterprise.",
      "features.exercises.title": "90 Ejercicios Prácticos",
      "features.exercises.description": "Cada módulo incluye 3 ejercicios prácticos (Fácil, Medio, Difícil) con orientación paso a paso.",
      "stats.modules": "Módulos Completos",
      "stats.exercises": "Ejercicios Prácticos",
      "stats.hours": "Horas de Contenido",
      "stats.productivity": "Aumento de Productividad",
      "stats.tools": "Herramientas IA Cubiertas",
      "stats.practical": "Enfoque Práctico",
      "tracks.title": "📚 Rutas de Aprendizaje",
      "tracks.subtitle": "Currículo progresivo diseñado para tu éxito",
      "cta.title": "🚀 ¿Listo para Dominar el Desarrollo con IA?",
      "cta.subtitle": "Únete a miles de desarrolladores que ya están construyendo el futuro con IA",
      "cta.start": "Empezar Ahora",
      "cta.prerequisites": "Verificar Prerrequisitos"
    }
  }
};

// Update JSON files with translations
function updateTranslations() {
  Object.keys(translations).forEach(locale => {
    const trans = translations[locale];
    
    // Update navbar translations
    const navbarPath = `i18n/${locale}/docusaurus-theme-classic/navbar.json`;
    if (fs.existsSync(navbarPath)) {
      fs.writeFileSync(navbarPath, JSON.stringify(trans.navbar, null, 2));
      console.log(`✅ Updated ${navbarPath}`);
    }
    
    // Update footer translations
    const footerPath = `i18n/${locale}/docusaurus-theme-classic/footer.json`;
    if (fs.existsSync(footerPath)) {
      fs.writeFileSync(footerPath, JSON.stringify(trans.footer, null, 2));
      console.log(`✅ Updated ${footerPath}`);
    }
    
    // Save homepage translations for later use
    const homepagePath = `i18n/${locale}/homepage.json`;
    fs.writeFileSync(homepagePath, JSON.stringify(trans.homepage, null, 2));
    console.log(`✅ Created ${homepagePath}`);
  });
}

// Create structure for content translations
function createContentStructure() {
  const locales = ['pt-BR', 'es'];
  
  locales.forEach(locale => {
    const docsDir = `i18n/${locale}/docusaurus-plugin-content-docs/current`;
    
    // Create directory if it doesn't exist
    if (!fs.existsSync(docsDir)) {
      fs.mkdirSync(docsDir, { recursive: true });
    }
    
    // Create a sample translation guide
    const guidePath = path.join(docsDir, 'TRANSLATION_GUIDE.md');
    const guideContent = `# Translation Guide for ${locale}

This folder should contain translated versions of all documentation files.

## Structure
- Copy the same folder structure from the \`docs\` folder
- Translate all .md and .mdx files
- Keep the same file names

## Important Notes
- Do not translate code blocks
- Keep all links and references the same
- Translate only the content, not technical terms that should remain in English

## Quick Start
To translate the documentation:
1. Copy files from \`docs\` to this folder
2. Translate the content
3. Test with \`npm run start:${locale}\`
`;
    
    fs.writeFileSync(guidePath, guideContent);
    console.log(`✅ Created translation guide for ${locale}`);
  });
}

// Main function
function main() {
  console.log('🌐 Preparing translations...\n');
  
  updateTranslations();
  createContentStructure();
  
  console.log('\n✅ Translation preparation complete!');
  console.log('\n📌 Next steps:');
  console.log('1. The UI translations have been added');
  console.log('2. To translate documentation content:');
  console.log('   - Copy docs to i18n/[locale]/docusaurus-plugin-content-docs/current/');
  console.log('   - Translate the content manually or with translation tools');
  console.log('3. Test translations:');
  console.log('   - npm run start:pt-BR');
  console.log('   - npm run start:es');
}

main();