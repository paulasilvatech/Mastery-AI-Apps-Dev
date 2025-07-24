# 🚀 Como Testar a Plataforma Docusaurus Localmente

## 1. Verificar se o servidor está rodando

```bash
# Se o servidor já está rodando, você verá a mensagem:
# [SUCCESS] Docusaurus website is running at: http://localhost:3000/Mastery-AI-Apps-Dev/

# Se não estiver rodando, execute:
npm run start
```

## 2. Acessar no navegador

Abra seu navegador e acesse:
```
http://localhost:3000/Mastery-AI-Apps-Dev/
```

## 3. O que testar

### 📚 Navegação Principal
- [ ] Homepage carrega corretamente
- [ ] Menu lateral mostra todos os 30 módulos organizados por tracks
- [ ] Links entre módulos funcionam

### 🎯 Por Track
1. **Fundamentals Track (Modules 1-5)**
   - [ ] Module 1: AI Development Fundamentals
   - [ ] Module 2: Copilot Mastery
   - [ ] Module 3: Advanced Prompt Engineering
   - [ ] Module 4: Testing & Debugging with AI
   - [ ] Module 5: Enterprise AI Integration

2. **Intermediate Track (Modules 6-10)**
   - [ ] Module 6: AI Pair Programming
   - [ ] Module 7: Copilot Workspace Guide
   - [ ] Module 8: API Development with AI
   - [ ] Module 9: Database & AI Integration
   - [ ] Module 10: Real-time Systems

3. **Advanced Track (Modules 11-15)**
   - [ ] Module 11: Microservices with AI
   - [ ] Module 12: Cloud-Native Development
   - [ ] Module 13: DevOps Automation
   - [ ] Module 14: Performance Optimization
   - [ ] Module 15: Security Best Practices

4. **Enterprise Track (Modules 16-20)**
   - [ ] Module 16: Enterprise Architecture
   - [ ] Module 17: System Integration
   - [ ] Module 18: Event-Driven Architecture
   - [ ] Module 19: Monitoring & Observability
   - [ ] Module 20: Production Deployment

5. **AI Agents Track (Modules 21-25)**
   - [ ] Module 21: AI Agents Fundamentals
   - [ ] Module 22: Custom AI Agents
   - [ ] Module 23: Model Context Protocol
   - [ ] Module 24: Multi-Agent Systems
   - [ ] Module 25: Production AI Agents

6. **Mastery Track (Modules 26-30)**
   - [ ] Module 26: Architecture Patterns
   - [ ] Module 27: Legacy Modernization
   - [ ] Module 28: Innovation Lab
   - [ ] Module 29: Capstone Project
   - [ ] Module 30: Final Assessment

### 📝 Por Módulo (exemplo: Module 1)
- [ ] README principal do módulo carrega
- [ ] Prerequisites page
- [ ] Exercise 1 (Part 1, 2, 3)
- [ ] Exercise 2 (Part 1, 2, 3)
- [ ] Exercise 3 (Part 1, 2, 3)
- [ ] Best Practices page

## 4. Comandos úteis

```bash
# Parar o servidor
# Pressione Ctrl+C no terminal

# Limpar cache e reiniciar
npm run clear
npm run start

# Build de produção (para testar performance)
npm run build
npm run serve

# Verificar links quebrados
npm run build
# O build mostrará warnings sobre links quebrados
```

## 5. Troubleshooting

### Erro de porta em uso
```bash
# Se aparecer "Something is already running on port 3000"
lsof -ti:3000 | xargs kill -9
npm run start
```

### Erros de MDX
- Se aparecer erros de compilação MDX, verifique os arquivos mencionados
- Problemas comuns: curly braces em código Python, sintaxe JSX incorreta

### Performance lenta
```bash
# Limpar cache do Docusaurus
rm -rf .docusaurus
rm -rf node_modules/.cache
npm run start
```

## 6. Testar funcionalidades específicas

### 🔍 Busca
- Use a barra de busca para procurar por termos como "Copilot", "API", "Docker"
- Verifique se os resultados são relevantes

### 📱 Responsividade
- Redimensione a janela do navegador
- Teste em modo mobile (F12 > Toggle device toolbar)

### 🌓 Tema escuro
- Clique no botão de tema (sol/lua) no canto superior direito
- Verifique se todas as páginas funcionam bem em ambos os temas

## 7. Verificar conteúdo educacional

Para cada módulo, verifique:
- [ ] Objetivos de aprendizagem claros
- [ ] Pré-requisitos listados
- [ ] Exercícios com instruções passo a passo
- [ ] Código de exemplo funcionando
- [ ] Links para recursos adicionais

## 8. Reportar problemas

Se encontrar algum problema:
1. Anote o módulo e página específica
2. Tire screenshot do erro (se houver)
3. Verifique o console do navegador (F12) para erros JavaScript
4. Verifique o terminal para erros do servidor

---

## 🎉 Sucesso!

Se tudo estiver funcionando, você verá:
- ✅ Navegação fluida entre módulos
- ✅ Conteúdo renderizado corretamente
- ✅ Código com syntax highlighting
- ✅ Imagens e diagramas carregando
- ✅ Links internos funcionando (exceto os que apontam para arquivos ainda não criados)