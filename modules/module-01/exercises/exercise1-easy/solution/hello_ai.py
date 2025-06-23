#!/usr/bin/env python3
"""
hello_ai.py - Solution
Complete implementation with GitHub Copilot assistance
"""

def generate_welcome_message(name: str, language: str = "English") -> str:
    """
    Generate a personalized welcome message.
    
    Args:
        name: The person's name to welcome
        language: The language for the greeting (default: English)
        
    Returns:
        A personalized welcome message string
    """
    greetings = {
        "English": f"Hello {name}! Welcome to AI-powered development with GitHub Copilot!",
        "Spanish": f"¡Hola {name}! ¡Bienvenido al desarrollo impulsado por IA con GitHub Copilot!",
        "French": f"Bonjour {name}! Bienvenue dans le développement alimenté par l'IA avec GitHub Copilot!",
        "Portuguese": f"Olá {name}! Bem-vindo ao desenvolvimento com IA usando GitHub Copilot!",
        "German": f"Hallo {name}! Willkommen zur KI-gestützten Entwicklung mit GitHub Copilot!"
    }
    
    return greetings.get(language, greetings["English"])

def get_time_based_greeting(name: str) -> str:
    """
    Generate a time-based greeting message.
    
    Args:
        name: The person's name
        
    Returns:
        A greeting based on the current time
    """
    from datetime import datetime
    
    current_hour = datetime.now().hour
    
    if 5 <= current_hour < 12:
        return f"Good morning, {name}! Ready to code with AI?"
    elif 12 <= current_hour < 17:
        return f"Good afternoon, {name}! Let's build something amazing!"
    elif 17 <= current_hour < 21:
        return f"Good evening, {name}! Time for some AI-powered coding!"
    else:
        return f"Hello, {name}! Burning the midnight oil with Copilot?"

def create_ascii_banner(text: str) -> str:
    """
    Create a simple ASCII art banner.
    
    Args:
        text: The text to display in the banner
        
    Returns:
        ASCII art banner as a string
    """
    border = "=" * (len(text) + 4)
    return f"{border}\n| {text} |\n{border}"

# Test the functions
if __name__ == "__main__":
    # Test personalized welcome
    name = input("What's your name? ")
    print("\n" + create_ascii_banner("GitHub Copilot Workshop"))
    print(generate_welcome_message(name))
    
    # Test multilingual welcome
    print("\nMultilingual greetings:")
    for lang in ["Spanish", "French", "Portuguese", "German"]:
        print(f"- {generate_welcome_message(name, lang)}")
    
    # Test time-based greeting
    print(f"\n{get_time_based_greeting(name)}")
    
    # Fun fact generated with Copilot
    print("\n💡 Fun fact: GitHub Copilot is powered by OpenAI Codex, a descendant of GPT-3!")
    print("It's trained on billions of lines of public code and can understand context across multiple files!")
