#!/usr/bin/env python3
"""
Simple translation script for Docusaurus content
Translates key UI elements and headers while preserving code blocks
"""

import os
import re
from pathlib import Path

# Translation mappings for common terms
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
        
        # Common phrases
        'Easy': 'Fácil',
        'Medium': 'Médio',
        'Hard': 'Difícil',
        'minutes': 'minutos',
        'Exercise': 'Exercício',
        'Part': 'Parte',
        'Module': 'Módulo',
        'Track': 'Trilha',
        'Fundamentals': 'Fundamentos',
        'Advanced': 'Avançado',
        'Enterprise': 'Empresarial',
        'Introduction': 'Introdução',
        'Overview': 'Visão Geral',
        'Summary': 'Resumo',
        'Conclusion': 'Conclusão',
        'Next Steps': 'Próximos Passos',
        'Resources': 'Recursos',
        'References': 'Referências',
        
        # Instructions
        'By completing this exercise, you will:': 'Ao completar este exercício, você irá:',
        'Before starting this exercise, ensure you have:': 'Antes de começar este exercício, certifique-se de que você tem:',
        'In this exercise, you\'ll create:': 'Neste exercício, você criará:',
        'This exercise is divided into': 'Este exercício está dividido em',
        'parts': 'partes',
        
        # Buttons and actions
        'Start Learning': 'Começar a Aprender',
        'Continue': 'Continuar',
        'Previous': 'Anterior',
        'Next': 'Próximo',
        'Complete': 'Completar',
        'Submit': 'Enviar',
        'Documentation': 'Documentação',
        'Tutorial': 'Tutorial',
        'Guide': 'Guia',
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
        
        # Common phrases
        'Easy': 'Fácil',
        'Medium': 'Medio',
        'Hard': 'Difícil',
        'minutes': 'minutos',
        'Exercise': 'Ejercicio',
        'Part': 'Parte',
        'Module': 'Módulo',
        'Track': 'Ruta',
        'Fundamentals': 'Fundamentos',
        'Advanced': 'Avanzado',
        'Enterprise': 'Empresarial',
        'Introduction': 'Introducción',
        'Overview': 'Resumen',
        'Summary': 'Resumen',
        'Conclusion': 'Conclusión',
        'Next Steps': 'Próximos Pasos',
        'Resources': 'Recursos',
        'References': 'Referencias',
        
        # Instructions
        'By completing this exercise, you will:': 'Al completar este ejercicio, usted:',
        'Before starting this exercise, ensure you have:': 'Antes de comenzar este ejercicio, asegúrese de tener:',
        'In this exercise, you\'ll create:': 'En este ejercicio, creará:',
        'This exercise is divided into': 'Este ejercicio está dividido en',
        'parts': 'partes',
        
        # Buttons and actions
        'Start Learning': 'Empezar a Aprender',
        'Continue': 'Continuar',
        'Previous': 'Anterior',
        'Next': 'Siguiente',
        'Complete': 'Completar',
        'Submit': 'Enviar',
        'Documentation': 'Documentación',
        'Tutorial': 'Tutorial',
        'Guide': 'Guía',
    }
}

def translate_line(line, translations):
    """Translate a line using the translation dictionary"""
    for eng, trans in translations.items():
        # Case-insensitive replacement for headers
        if line.strip().startswith('#'):
            line = re.sub(re.escape(eng), trans, line, flags=re.IGNORECASE)
        else:
            line = line.replace(eng, trans)
    return line

def translate_file(file_path, locale):
    """Translate a markdown file"""
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
        
        # Don't translate code blocks
        if in_code_block:
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
        
        # Translate all markdown files
        for md_file in Path(docs_dir).rglob('*.md'):
            print(f"  📝 Translating {md_file.name}...")
            translate_file(str(md_file), locale)
        
        for mdx_file in Path(docs_dir).rglob('*.mdx'):
            print(f"  📝 Translating {mdx_file.name}...")
            translate_file(str(mdx_file), locale)
    
    print("\n✅ Basic translation completed!")
    print("\n📌 Note: This is a basic translation of UI elements and headers.")
    print("Full content translation would require professional translation services.")

if __name__ == "__main__":
    main()