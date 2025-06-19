#!/usr/bin/env python3
"""
Hello AI World - Complete Solution
Module 01, Exercise 1: Introduction to GitHub Copilot

This is a complete implementation of the personalized greeting program.
It demonstrates basic GitHub Copilot usage patterns and best practices.
"""

import datetime
import random
from typing import Optional

def get_time_period() -> str:
    """
    Determine the current time period based on the hour.
    
    Returns:
        str: "morning", "afternoon", "evening", or "night"
    """
    current_hour = datetime.datetime.now().hour
    
    if 5 <= current_hour < 12:
        return "morning"
    elif 12 <= current_hour < 18:
        return "afternoon"
    elif 18 <= current_hour < 23:
        return "evening"
    else:
        return "night"

# Dictionary with greetings in different languages
GREETINGS = {
    "english": {
        "morning": "Good morning",
        "afternoon": "Good afternoon",
        "evening": "Good evening",
        "night": "Good night"
    },
    "spanish": {
        "morning": "Buenos días",
        "afternoon": "Buenas tardes",
        "evening": "Buenas noches",
        "night": "Buenas noches"
    },
    "french": {
        "morning": "Bonjour",
        "afternoon": "Bon après-midi",
        "evening": "Bonsoir",
        "night": "Bonne nuit"
    },
    "german": {
        "morning": "Guten Morgen",
        "afternoon": "Guten Tag",
        "evening": "Guten Abend",
        "night": "Gute Nacht"
    },
    "japanese": {
        "morning": "おはようございます",
        "afternoon": "こんにちは",
        "evening": "こんばんは",
        "night": "おやすみなさい"
    },
    "portuguese": {
        "morning": "Bom dia",
        "afternoon": "Boa tarde",
        "evening": "Boa noite",
        "night": "Boa noite"
    }
}

# Fun facts about programming, AI, and technology
FUN_FACTS = [
    "The first computer bug was an actual moth found in a Harvard Mark II computer in 1947!",
    "Python was named after Monty Python, not the snake!",
    "The first programmer was Ada Lovelace in the 1840s!",
    "GitHub's mascot 'Octocat' has a name - it's Mona!",
    "The term 'debugging' came from Grace Hopper removing a moth from a computer!",
    "Alan Turing created the first computer chess program in 1951 - on paper!",
    "The first computer virus was created in 1983 and was called 'Elk Cloner'!",
    "Linux's mascot Tux the penguin was chosen because Linus Torvalds was bitten by a penguin!",
    "The '@' symbol was used in email addresses because it was the least used character on keyboards!",
    "JavaScript was created in just 10 days by Brendan Eich in 1995!",
    "The first 1GB hard drive weighed 550 pounds and cost $40,000 in 1980!",
    "GitHub Copilot is powered by OpenAI Codex, which understands over a dozen programming languages!"
]

# Emojis for different times of day
TIME_EMOJIS = {
    "morning": "🌅",
    "afternoon": "🌞",
    "evening": "🌙",
    "night": "🌃"
}

def get_greeting(name: str, time_period: str, language: str = 'english') -> str:
    """
    Get a greeting in the specified language and time.
    
    Args:
        name: The person's name
        time_period: Current time period (morning, afternoon, evening, night)
        language: Language for the greeting (default: english)
    
    Returns:
        Formatted greeting string with emoji
    """
    # Validate language, fall back to English if not found
    if language.lower() not in GREETINGS:
        print(f"Language '{language}' not found. Using English.")
        language = "english"
    
    greeting = GREETINGS[language.lower()][time_period]
    emoji = TIME_EMOJIS.get(time_period, "👋")
    
    return f"{greeting}, {name}! {emoji}"

def get_fun_fact() -> str:
    """
    Get a random fun fact from the collection.
    
    Returns:
        A random fun fact string
    """
    return random.choice(FUN_FACTS)

def get_fun_fact_translation(language: str) -> str:
    """
    Get the 'Did you know?' phrase in different languages.
    
    Args:
        language: Target language
    
    Returns:
        Translated phrase
    """
    translations = {
        "english": "Did you know?",
        "spanish": "¿Sabías que?",
        "french": "Le saviez-vous?",
        "german": "Wussten Sie schon?",
        "japanese": "知っていましたか？",
        "portuguese": "Você sabia?"
    }
    return translations.get(language.lower(), "Did you know?")

def generate_personalized_greeting(name: Optional[str], language: str = 'english') -> str:
    """
    Generate a complete personalized greeting with fun fact.
    
    Args:
        name: The person's name
        language: Preferred language for the greeting
    
    Returns:
        Complete formatted greeting message
    """
    # Validate name
    if not name or not name.strip():
        name = "Friend"
    
    # Get current time period
    time_period = get_time_period()
    
    # Get the greeting
    greeting = get_greeting(name.strip(), time_period, language)
    
    # Get a fun fact
    fun_fact = get_fun_fact()
    fun_fact_intro = get_fun_fact_translation(language)
    
    # Create separator
    separator = "-" * 50
    
    # Format the complete message
    message = f"""
{greeting}
{fun_fact_intro} {fun_fact}
{separator}
"""
    
    return message

def display_available_languages():
    """Display all available languages."""
    print("\nAvailable languages:")
    for i, lang in enumerate(GREETINGS.keys(), 1):
        print(f"{i}. {lang.capitalize()}")

def main():
    """Main function to run the Hello AI World program."""
    print("=" * 50)
    print("🤖 Welcome to Hello AI World! 🌍")
    print("Your first AI-assisted program with GitHub Copilot")
    print("=" * 50)
    
    while True:
        # Get user's name
        name = input("\n👤 What's your name? (or 'quit' to exit): ").strip()
        
        if name.lower() in ['quit', 'exit', 'q']:
            print("\n👋 Goodbye! Happy coding with GitHub Copilot!")
            break
        
        # Show available languages
        display_available_languages()
        
        # Get preferred language
        language_choice = input("\n🌐 Choose a language (number or name): ").strip()
        
        # Handle numeric input
        if language_choice.isdigit():
            language_list = list(GREETINGS.keys())
            idx = int(language_choice) - 1
            if 0 <= idx < len(language_list):
                language = language_list[idx]
            else:
                print("Invalid choice. Using English.")
                language = "english"
        else:
            language = language_choice.lower()
        
        # Generate and display greeting
        greeting = generate_personalized_greeting(name, language)
        print(greeting)
        
        # Ask if they want another greeting
        another = input("Would you like another greeting? (yes/no): ").strip().lower()
        if another not in ['yes', 'y']:
            print("\n👋 Thanks for using Hello AI World! Happy coding!")
            break

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n👋 Goodbye! Keep exploring with GitHub Copilot!")
    except Exception as e:
        print(f"\n❌ An error occurred: {e}")
        print("Please try again or report this issue.")