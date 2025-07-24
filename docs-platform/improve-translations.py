#!/usr/bin/env python3
"""
Enhanced translation script for Docusaurus content
Translates more content while preserving code blocks and technical terms
"""

import os
import re
from pathlib import Path

# Extended translation mappings
TRANSLATIONS = {
    'pt-BR': {
        # Headers and titles
        'Welcome to AI Mastery Workshop': 'Bem-vindo ao Workshop de Maestria em IA',
        'Master AI Apps Development': 'Domine o Desenvolvimento de Apps com IA',
        'What You\'ll Learn': 'O Que Você Aprenderá',
        'Getting Started': 'Começando',
        'Prerequisites': 'Pré-requisitos',
        'Workshop Structure': 'Estrutura do Workshop',
        'Learning Objectives': 'Objetivos de Aprendizagem',
        'Exercise Overview': 'Visão Geral do Exercício',
        'Best Practices': 'Melhores Práticas',
        'Key Concepts': 'Conceitos-Chave',
        'Setup Instructions': 'Instruções de Configuração',
        'Module Overview': 'Visão Geral do Módulo',
        'Learning Path': 'Caminho de Aprendizagem',
        'Required Tools': 'Ferramentas Necessárias',
        'Community & Support': 'Comunidade e Suporte',
        'Your Journey Starts Here': 'Sua Jornada Começa Aqui',
        'Introduction': 'Introdução',
        'Overview': 'Visão Geral',
        'Summary': 'Resumo',
        'Conclusion': 'Conclusão',
        'Next Steps': 'Próximos Passos',
        'Resources': 'Recursos',
        'References': 'Referências',
        'Documentation': 'Documentação',
        'Tutorial': 'Tutorial',
        'Guide': 'Guia',
        
        # Common phrases
        'Easy': 'Fácil',
        'Medium': 'Médio',
        'Hard': 'Difícil',
        'minutes': 'minutos',
        'hours': 'horas',
        'Exercise': 'Exercício',
        'Part': 'Parte',
        'Module': 'Módulo',
        'Track': 'Trilha',
        'Fundamentals': 'Fundamentos',
        'Advanced': 'Avançado',
        'Enterprise': 'Empresarial',
        'Beginner': 'Iniciante',
        'Intermediate': 'Intermediário',
        
        # Extended content phrases
        'By completing this exercise, you will:': 'Ao completar este exercício, você irá:',
        'Before starting this exercise, ensure you have:': 'Antes de começar este exercício, certifique-se de que você tem:',
        'In this exercise, you\'ll create:': 'Neste exercício, você criará:',
        'This exercise is divided into': 'Este exercício está dividido em',
        'By the end of this module, you will be able to:': 'Ao final deste módulo, você será capaz de:',
        'Welcome to the beginning of your AI-powered development journey!': 'Bem-vindo ao início da sua jornada de desenvolvimento com IA!',
        'Duration': 'Duração',
        'Total Time': 'Tempo Total',
        'Hands-on Exercises': 'Exercícios Práticos',
        'For Beginners': 'Para Iniciantes',
        'For Experienced Developers': 'Para Desenvolvedores Experientes',
        'For Enterprise Architects': 'Para Arquitetos Empresariais',
        'Start with': 'Comece com',
        'Focus on': 'Foque em',
        'You can jump to': 'Você pode pular para',
        'based on your interests': 'baseado em seus interesses',
        'specific tracks': 'trilhas específicas',
        'progress sequentially': 'progrida sequencialmente',
        'through each module': 'através de cada módulo',
        
        # Instructions and actions
        'Start Learning': 'Começar a Aprender',
        'Continue': 'Continuar',
        'Previous': 'Anterior',
        'Next': 'Próximo',
        'Complete': 'Completar',
        'Submit': 'Enviar',
        'Check': 'Verificar',
        'Review': 'Revisar',
        'Follow': 'Seguir',
        'Begin with': 'Comece com',
        'Set Up': 'Configurar',
        
        # Technical terms (partial translation)
        'subscription': 'assinatura',
        'installed': 'instalado',
        'configured': 'configurado',
        'account': 'conta',
        'environment': 'ambiente',
        'development': 'desenvolvimento',
        'production': 'produção',
        'deployment': 'implantação',
        
        # UI Elements
        'Get Started': 'Começar',
        'Learn More': 'Saiba Mais',
        'View Details': 'Ver Detalhes',
        'Download': 'Baixar',
        'Upload': 'Enviar',
        'Save': 'Salvar',
        'Cancel': 'Cancelar',
        'Close': 'Fechar',
        'Open': 'Abrir',
        'Edit': 'Editar',
        'Delete': 'Excluir',
        'Share': 'Compartilhar',
        'Copy': 'Copiar',
        'Paste': 'Colar',
        'Search': 'Pesquisar',
        'Filter': 'Filtrar',
        'Sort': 'Ordenar',
        'Help': 'Ajuda',
        'Settings': 'Configurações',
        'Profile': 'Perfil',
        'Logout': 'Sair',
        'Login': 'Entrar',
        'Register': 'Registrar',
        'Forgot Password': 'Esqueceu a Senha',
        'Reset Password': 'Redefinir Senha',
        'Update': 'Atualizar',
        'Refresh': 'Atualizar',
        'Back': 'Voltar',
        'Forward': 'Avançar',
        'Home': 'Início',
        'Dashboard': 'Painel',
        'Reports': 'Relatórios',
        'Analytics': 'Análises',
        'Notifications': 'Notificações',
        'Messages': 'Mensagens',
        'Tasks': 'Tarefas',
        'Projects': 'Projetos',
        'Calendar': 'Calendário',
        'Timeline': 'Linha do Tempo',
        'History': 'Histórico',
        'Version': 'Versão',
        'Language': 'Idioma',
        'Theme': 'Tema',
        'Dark Mode': 'Modo Escuro',
        'Light Mode': 'Modo Claro',
    },
    'es': {
        # Headers and titles
        'Welcome to AI Mastery Workshop': 'Bienvenido al Taller de Maestría en IA',
        'Master AI Apps Development': 'Domina el Desarrollo de Apps con IA',
        'What You\'ll Learn': 'Lo Que Aprenderás',
        'Getting Started': 'Comenzando',
        'Prerequisites': 'Prerrequisitos',
        'Workshop Structure': 'Estructura del Taller',
        'Learning Objectives': 'Objetivos de Aprendizaje',
        'Exercise Overview': 'Resumen del Ejercicio',
        'Best Practices': 'Mejores Prácticas',
        'Key Concepts': 'Conceptos Clave',
        'Setup Instructions': 'Instrucciones de Configuración',
        'Module Overview': 'Resumen del Módulo',
        'Learning Path': 'Ruta de Aprendizaje',
        'Required Tools': 'Herramientas Requeridas',
        'Community & Support': 'Comunidad y Soporte',
        'Your Journey Starts Here': 'Tu Viaje Comienza Aquí',
        'Introduction': 'Introducción',
        'Overview': 'Resumen',
        'Summary': 'Resumen',
        'Conclusion': 'Conclusión',
        'Next Steps': 'Próximos Pasos',
        'Resources': 'Recursos',
        'References': 'Referencias',
        'Documentation': 'Documentación',
        'Tutorial': 'Tutorial',
        'Guide': 'Guía',
        
        # Common phrases
        'Easy': 'Fácil',
        'Medium': 'Medio',
        'Hard': 'Difícil',
        'minutes': 'minutos',
        'hours': 'horas',
        'Exercise': 'Ejercicio',
        'Part': 'Parte',
        'Module': 'Módulo',
        'Track': 'Ruta',
        'Fundamentals': 'Fundamentos',
        'Advanced': 'Avanzado',
        'Enterprise': 'Empresarial',
        'Beginner': 'Principiante',
        'Intermediate': 'Intermedio',
        
        # Extended content phrases
        'By completing this exercise, you will:': 'Al completar este ejercicio, usted:',
        'Before starting this exercise, ensure you have:': 'Antes de comenzar este ejercicio, asegúrese de tener:',
        'In this exercise, you\'ll create:': 'En este ejercicio, creará:',
        'This exercise is divided into': 'Este ejercicio está dividido en',
        'By the end of this module, you will be able to:': 'Al final de este módulo, usted será capaz de:',
        'Welcome to the beginning of your AI-powered development journey!': '¡Bienvenido al inicio de su viaje de desarrollo con IA!',
        'Duration': 'Duración',
        'Total Time': 'Tiempo Total',
        'Hands-on Exercises': 'Ejercicios Prácticos',
        'For Beginners': 'Para Principiantes',
        'For Experienced Developers': 'Para Desarrolladores Experimentados',
        'For Enterprise Architects': 'Para Arquitectos Empresariales',
        'Start with': 'Comience con',
        'Focus on': 'Enfóquese en',
        'You can jump to': 'Puede saltar a',
        'based on your interests': 'basado en sus intereses',
        'specific tracks': 'rutas específicas',
        'progress sequentially': 'progrese secuencialmente',
        'through each module': 'a través de cada módulo',
        
        # Instructions and actions
        'Start Learning': 'Empezar a Aprender',
        'Continue': 'Continuar',
        'Previous': 'Anterior',
        'Next': 'Siguiente',
        'Complete': 'Completar',
        'Submit': 'Enviar',
        'Check': 'Verificar',
        'Review': 'Revisar',
        'Follow': 'Seguir',
        'Begin with': 'Comience con',
        'Set Up': 'Configurar',
        
        # Technical terms (partial translation)
        'subscription': 'suscripción',
        'installed': 'instalado',
        'configured': 'configurado',
        'account': 'cuenta',
        'environment': 'ambiente',
        'development': 'desarrollo',
        'production': 'producción',
        'deployment': 'despliegue',
        
        # UI Elements
        'Get Started': 'Comenzar',
        'Learn More': 'Aprende Más',
        'View Details': 'Ver Detalles',
        'Download': 'Descargar',
        'Upload': 'Subir',
        'Save': 'Guardar',
        'Cancel': 'Cancelar',
        'Close': 'Cerrar',
        'Open': 'Abrir',
        'Edit': 'Editar',
        'Delete': 'Eliminar',
        'Share': 'Compartir',
        'Copy': 'Copiar',
        'Paste': 'Pegar',
        'Search': 'Buscar',
        'Filter': 'Filtrar',
        'Sort': 'Ordenar',
        'Help': 'Ayuda',
        'Settings': 'Configuraciones',
        'Profile': 'Perfil',
        'Logout': 'Salir',
        'Login': 'Entrar',
        'Register': 'Registrar',
        'Forgot Password': 'Olvidó la Contraseña',
        'Reset Password': 'Restablecer Contraseña',
        'Update': 'Actualizar',
        'Refresh': 'Actualizar',
        'Back': 'Atrás',
        'Forward': 'Adelante',
        'Home': 'Inicio',
        'Dashboard': 'Panel',
        'Reports': 'Informes',
        'Analytics': 'Análisis',
        'Notifications': 'Notificaciones',
        'Messages': 'Mensajes',
        'Tasks': 'Tareas',
        'Projects': 'Proyectos',
        'Calendar': 'Calendario',
        'Timeline': 'Línea de Tiempo',
        'History': 'Historial',
        'Version': 'Versión',
        'Language': 'Idioma',
        'Theme': 'Tema',
        'Dark Mode': 'Modo Oscuro',
        'Light Mode': 'Modo Claro',
    }
}

def translate_line(line, translations):
    """Translate a line using the translation dictionary"""
    for eng, trans in sorted(translations.items(), key=lambda x: len(x[0]), reverse=True):
        # Case-insensitive replacement for headers
        if line.strip().startswith('#'):
            line = re.sub(re.escape(eng), trans, line, flags=re.IGNORECASE)
        else:
            # Regular replacement for body text
            line = line.replace(eng, trans)
    return line

def translate_file(file_path, locale):
    """Translate a markdown file with improved content translation"""
    translations = TRANSLATIONS.get(locale, {})
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    lines = content.split('\n')
    translated_lines = []
    in_code_block = False
    in_frontmatter = False
    
    for line in lines:
        # Check for frontmatter
        if line.strip() == '---':
            in_frontmatter = not in_frontmatter
            translated_lines.append(line)
            continue
            
        # Don't translate frontmatter
        if in_frontmatter:
            translated_lines.append(line)
            continue
            
        # Check for code blocks
        if line.strip().startswith('```'):
            in_code_block = not in_code_block
            translated_lines.append(line)
            continue
        
        # Don't translate code blocks or lines starting with certain patterns
        if in_code_block or line.strip().startswith(('import ', 'export ', 'const ', 'let ', 'var ', 'function ', 'class ', '//', '/*', '*/', '<', '>')):
            translated_lines.append(line)
            continue
        
        # Don't translate lines that look like code (contain certain patterns)
        if any(pattern in line for pattern in ['${', '{{', '}}', 'className=', 'href=', 'src=', '() =>', '=>', 'async', 'await']):
            translated_lines.append(line)
            continue
        
        # Translate the line
        translated_line = translate_line(line, translations)
        translated_lines.append(translated_line)
    
    # Write the translated content
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(translated_lines))

def main():
    """Main translation function"""
    locales = ['pt-BR', 'es']
    
    for locale in locales:
        print(f"\n🌐 Translating content to {locale}...")
        
        docs_dir = f'i18n/{locale}/docusaurus-plugin-content-docs/current'
        
        # Count files
        md_files = list(Path(docs_dir).rglob('*.md'))
        mdx_files = list(Path(docs_dir).rglob('*.mdx'))
        total_files = len(md_files) + len(mdx_files)
        
        print(f"  📊 Found {total_files} files to translate")
        
        # Translate all markdown files
        translated_count = 0
        for i, md_file in enumerate(md_files):
            print(f"  📝 Translating ({i+1}/{len(md_files)}): {md_file.name}...")
            try:
                translate_file(str(md_file), locale)
                translated_count += 1
            except Exception as e:
                print(f"    ⚠️  Error: {e}")
        
        # Translate all MDX files
        for i, mdx_file in enumerate(mdx_files):
            print(f"  📝 Translating MDX ({i+1}/{len(mdx_files)}): {mdx_file.name}...")
            try:
                translate_file(str(mdx_file), locale)
                translated_count += 1
            except Exception as e:
                print(f"    ⚠️  Error: {e}")
        
        print(f"  ✅ Translated {translated_count}/{total_files} files for {locale}")
    
    print("\n✅ Enhanced translation completed!")
    print("\n📌 Note: This provides basic UI and content translation.")
    print("For production use, professional translation services are recommended.")

if __name__ == "__main__":
    main()