---
id: quick-start
title: Quick Start Guide
sidebar_label: Quick Start
sidebar_position: 3
---

# Quick Start Guía

Get up and running with AI application desarrollo in just 15 minutos!

## Resumen

This guide will help you:
- Set up your desarrollo ambiente
- Create your first AI-powered application
- Understand the basic concepts
- Know where to go next

## 🚀 5-Minute Setup

### Step 1: Create Project Directory

```bash
# Create and enter your project directory
mkdir my-ai-app
cd my-ai-app
```

### Step 2: Configurar Python ambiente

```bash
# Create virtual environment
python -m venv venv

# Activate it
# Windows:
venv\Scripts\activate
# Mac/Linux:
source venv/bin/activate
```

### Step 3: Install Dependencies

```bash
# Install OpenAI library
pip install openai python-dotenv
```

### Step 4: Configure API Keys

Create `.env` file:
```bash
OPENAI_API_KEY=your-api-key-here
```

## 🤖 Your First AI Application

### Simple Chat Application

Create `app.py`:

```python
import os
from openai import OpenAI
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize OpenAI client
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

def chat_with_ai(prompt):
    """Send a prompt to AI and get response"""
    try:
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.7,
            max_tokens=150
        )
        return response.choices[0].message.content
    except Exception as e:
        return f"Error: {str(e)}"

# Test it
if __name__ == "__main__":
    print("AI Chat Application")
    print("-" * 50)
    
    while True:
        user_input = input("\nYou: ")
        if user_input.lower() in ['quit', 'exit', 'bye']:
            print("Goodbye!")
            break
        
        response = chat_with_ai(user_input)
        print(f"\nAI: {response}")
```

### Run Your Application

```bash
python app.py
```

## 🎯 Quick Examples

### Example 1: Text Summarizer

```python
def summarize_text(text):
    """Summarize long text into key points"""
    prompt = f"Summarize this text in 3 bullet points:\n\n{text}"
    return chat_with_ai(prompt)

# Example usage
long_text = """
Artificial Intelligence is transforming how we work and live. 
Machine learning models can now understand and generate human-like text,
recognize images, translate languages, and even write code. This technology
is being integrated into everyday applications, from email assistants to
code completion tools, making tasks more efficient and accessible.
"""

summary = summarize_text(long_text)
print(summary)
```

### Example 2: Code Ayudaer

```python
def explain_code(code):
    """Get AI to explain code"""
    prompt = f"Explain this code in simple terms:\n```python\n{code}\n```"
    return chat_with_ai(prompt)

# Example usage
code_snippet = """
def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)
"""

explanation = explain_code(code_snippet)
print(explanation)
```

### Example 3: Data Analyzer

```python
def analyze_data(data):
    """Get insights from data"""
    prompt = f"Analyze this data and provide 3 key insights:\n{data}"
    return chat_with_ai(prompt)

# Example usage
sales_data = """
Month | Sales | Growth
Jan   | $10K  | -
Feb   | $12K  | 20%
Mar   | $15K  | 25%
Apr   | $14K  | -7%
May   | $18K  | 29%
"""

insights = analyze_data(sales_data)
print(insights)
```

## 🛠️ Quick Enhancements

### Add Streaming Responses

```python
def chat_with_ai_stream(prompt):
    """Stream AI responses for better UX"""
    stream = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[{"role": "user", "content": prompt}],
        stream=True
    )
    
    for chunk in stream:
        if chunk.choices[0].delta.content:
            print(chunk.choices[0].delta.content, end='', flush=True)
```

### Add Conversation Memory

```python
class ChatBot:
    def __init__(self):
        self.messages = [
            {"role": "system", "content": "You are a helpful assistant."}
        ]
    
    def chat(self, user_input):
        self.messages.append({"role": "user", "content": user_input})
        
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=self.messages
        )
        
        ai_response = response.choices[0].message.content
        self.messages.append({"role": "assistant", "content": ai_response})
        
        return ai_response

# Usage
bot = ChatBot()
print(bot.chat("What's the capital of France?"))
print(bot.chat("What's the population there?"))  # Remembers context!
```

### Add Error Handling

```python
import time

def chat_with_retry(prompt, max_retries=3):
    """Chat with automatic retry on failure"""
    for attempt in range(max_retries):
        try:
            return chat_with_ai(prompt)
        except Exception as e:
            if attempt < max_retries - 1:
                wait_time = 2 ** attempt  # Exponential backoff
                print(f"Error: {e}. Retrying in {wait_time}s...")
                time.sleep(wait_time)
            else:
                return f"Failed after {max_retries} attempts: {e}"
```

## 🌐 Quick Web Interface

Create a simple web interface with Streamlit:

```bash
pip install streamlit
```

Create `web_app.py`:

```python
import streamlit as st
from openai import OpenAI
import os
from dotenv import load_dotenv

load_dotenv()
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

st.title("🤖 AI Chat Assistant")
st.write("Ask me anything!")

# Initialize chat history
if "messages" not in st.session_state:
    st.session_state.messages = []

# Display chat history
for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.write(message["content"])

# Chat input
if prompt := st.chat_input("Type your message here..."):
    # Add user message
    st.session_state.messages.append({"role": "user", "content": prompt})
    with st.chat_message("user"):
        st.write(prompt)
    
    # Get AI response
    with st.chat_message("assistant"):
        with st.spinner("Thinking..."):
            response = client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": m["role"], "content": m["content"]}
                    for m in st.session_state.messages
                ]
            )
            ai_response = response.choices[0].message.content
            st.write(ai_response)
    
    # Add AI response to history
    st.session_state.messages.append({"role": "assistant", "content": ai_response})
```

Run the web app:
```bash
streamlit run web_app.py
```

## 📚 Quick Concepts

### Tokens
- Basic units of text (roughly 4 characters)
- Affects cost and context limits
- Example: "Hello, world!" ≈ 3 tokens

### Temperature
- Controls randomness (0-2)
- 0 = Deterministic
- 1 = Balanced
- 2 = Creative/Random

### Models
- **GPT-3.5-turbo**: Fast, affordable, good for most tasks
- **GPT-4**: More capable, better reasoning
- **GPT-4-turbo**: Best performance, higher cost

### Prompting Tips
1. Be specific and clear
2. Provide examples
3. Set the right context
4. Iterate and refine

## 🚨 Quick Troubleshooting

### Common Issues

1. **"API key not valid"**
   - Verificar your .env file
   - Ensure no extra spaces
   - Verify key on AbrirAI dashboard

2. **"Rate limit exceeded"**
   - Add delays between requests
   - Implement exponential backoff
   - Verificar your usage limits

3. **"Módulo not found"**
   - Activate virtual ambiente
   - Run `pip install -r requirements.txt`
   - Verificar Python version

### Quick Fixes

```python
# Fix 1: Better error messages
try:
    response = chat_with_ai(prompt)
except Exception as e:
    print(f"Detailed error: {type(e).__name__}: {str(e)}")

# Fix 2: Check API key
if not os.getenv("OPENAI_API_KEY"):
    print("Error: OPENAI_API_KEY not found in environment variables")

# Fix 3: Debug mode
import logging
logging.basicConfig(level=logging.DEBUG)
```

## 🎯 Próximos Pasos

### Immediate Próximos Pasos (Today)

1. **Experiment with prompts**: Try different styles and see results
2. **Build a simple tool**: Create something useful for yourself
3. **Explore parameters**: Play with temperature, max_tokens, etc.

### This Week

1. Completar [Módulo 1: Fundamentos](../modules/module-01-fundamentals.md)
2. Learn about [Effective Prompts](./effective-prompts.md)
3. Build a more complex application

### This Month

1. Master RAG systems
2. Build multi-agent applications
3. Deploy to producción
4. Contribute to open source

## 🎉 Congratulations!

You've just:
- ✅ Set up an AI desarrollo ambiente
- ✅ Created your first AI application
- ✅ Learned basic concepts
- ✅ Built a web interface

**You're now ready to dive deeper into AI application desarrollo!**

## 📌 Quick Reference

### Essential Commands

```bash
# Activate virtual environment
source venv/bin/activate  # Mac/Linux
venv\Scripts\activate     # Windows

# Install packages
pip install openai streamlit

# Run applications
python app.py
streamlit run web_app.py

# Check installations
pip list
python --version
```

### Useful Recursos

- [AbrirAI Documentación](https://platform.openai.com/docs)
- [Python AI Cookbook](https://github.com/openai/openai-cookbook)
- [Streamlit Documentación](https://docs.streamlit.io)
- [Our Workshop Repository](https://github.com/workshop/ai-apps)

### Get Ayuda

- 💬 Join our Discord/Slack
- 📧 Email: support@workshop.ai
- 📚 Verificar [Troubleshooting Guía](./troubleshooting.md)
- 🤝 Pair with fellow learners

---

**Ready for more? Continue to [Setup Local Environment](./setup-local.md) →**