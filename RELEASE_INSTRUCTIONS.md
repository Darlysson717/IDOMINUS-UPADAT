# Instruções para Criar Release v1.0.3 no GitHub

## 📋 Checklist Antes de Criar a Release

### ✅ Já Feito:
- [x] Tag v1.0.3 criada e enviada
- [x] APK release gerado e assinado
- [x] Commit com mudanças enviado
- [x] update.json atualizado para v1.0.3

### 📝 Para Criar no GitHub:

1. **Acesse o repositório**: https://github.com/Darlysson717/IDOMINUS-UPADAT

2. **Clique em "Releases"** (no menu lateral direito)

3. **Clique em "Create a new release"**

4. **Preencha os campos**:
   - **Tag version**: `v1.0.3` (selecionar da lista)
   - **Release title**: `Release v1.0.3 - Compartilhamento e Deep Linking`
   - **Describe this release**:
     ```
     ## 🚀 Novidades da Release v1.0.3

     ### ✨ Funcionalidades
     - ✅ Compartilhamento inteligente de anúncios
     - ✅ Deep linking para links https://domin.us/vehicle/{id}
     - ✅ UI aprimorada com ícones FontAwesome
     - ✅ Temas dark/light consistentes
     - ✅ Performance otimizada (scroll, carregamento)

     ### 🐛 Correções
     - ✅ Problemas de BuildContext em async gaps
     - ✅ APIs deprecated atualizadas
     - ✅ Warnings do Flutter reduzidos
     - ✅ Testes básicos implementados

     ### 📱 Arquivos
     - APK Release assinado: `app-release.apk` (25.7MB)
     - Compatível com Android 5.0+
     - Otimizado com tree-shaking

     ### 🔗 Deep Linking
     Configure o domínio domin.us para redirecionamento inteligente:
     - App instalado → Abre anúncio diretamente
     - App não instalado → Página de download

     ---
     **Download**: Baixe o APK anexado abaixo
     ```

5. **Anexe o APK**:
   - Clique em "Attach binaries by dropping them here or selecting them"
   - Selecione: `C:\Users\darly\Desktop\triunvirato car\triunvirato_car_marketplace\build\app\outputs\flutter-apk\app-release.apk`

6. **Marque como "Pre-release"** se quiser testar primeiro

7. **Clique em "Publish release"**

## 🎯 Após Criar a Release

- **Compartilhe o link** da release com usuários beta
- **Monitore feedback** e issues
- **Prepare próxima versão** (v1.0.4) se necessário

## 📊 Status da Release
- ✅ Código commitado
- ✅ Tag criada
- ✅ APK gerado
- ✅ update.json atualizado
- 🔄 Release no GitHub (pendente)
- 🔄 Upload para Play Store (opcional)