#!/usr/bin/env python3
"""
test_hello_ai.py - Tests for hello_ai functions
This file demonstrates how to use Copilot to generate tests
"""

import unittest
from solution.hello_ai import (
    generate_welcome_message,
    get_time_based_greeting,
    create_ascii_banner
)

class TestHelloAI(unittest.TestCase):
    """Test cases for hello_ai functions"""
    
    def test_generate_welcome_message_default(self):
        """Test welcome message with default language"""
        result = generate_welcome_message("Alice")
        self.assertIn("Alice", result)
        self.assertIn("GitHub Copilot", result)
    
    def test_generate_welcome_message_spanish(self):
        """Test welcome message in Spanish"""
        result = generate_welcome_message("Carlos", "Spanish")
        self.assertIn("Carlos", result)
        self.assertIn("¡Hola", result)
    
    def test_generate_welcome_message_invalid_language(self):
        """Test welcome message with invalid language falls back to English"""
        result = generate_welcome_message("Bob", "Klingon")
        self.assertIn("Bob", result)
        self.assertIn("Hello", result)
    
    def test_get_time_based_greeting(self):
        """Test time-based greeting includes name"""
        result = get_time_based_greeting("Diana")
        self.assertIn("Diana", result)
        # Should contain one of the time-based greetings
        time_words = ["morning", "afternoon", "evening", "midnight"]
        self.assertTrue(any(word in result.lower() for word in time_words))
    
    def test_create_ascii_banner(self):
        """Test ASCII banner creation"""
        text = "Test"
        result = create_ascii_banner(text)
        self.assertIn(text, result)
        self.assertIn("=", result)  # Should have border
        self.assertEqual(result.count("\n"), 2)  # Should have 3 lines

if __name__ == "__main__":
    unittest.main()
