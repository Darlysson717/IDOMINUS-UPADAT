# Sistema de Notificações (Sem Firebase)

Este sistema implementa notificações que funcionam **mesmo quando o usuário não está logado no app**, usando uma abordagem sem Firebase.

## 🔧 Como Funciona

### Sistema Atual:
1. **Notificações Locais**: Aparecem quando o usuário está usando o app
2. **Verificação em Background**: WorkManager verifica notificações pendentes a cada 15 minutos
3. **Notificações Push-Like**: Simula push notifications através de verificação periódica

### Fluxo:
1. Alguém favorita seu anúncio → Notificação inserida no banco
2. WorkManager verifica periodicamente → Encontra notificações não lidas
3. Mostra notificação local → Mesmo com app fechado/minimizado

## 📋 Vantagens desta Abordagem

- ✅ **Sem Firebase**: Não depende de serviços externos
- ✅ **Simples**: Usa apenas Supabase + WorkManager
- ✅ **Privacidade**: Dados ficam no seu banco
- ✅ **Controle Total**: Você controla quando/todas as notificações

## ⚠️ Limitações

- **Atraso**: Notificações chegam com até 15 minutos de atraso
- **Bateria**: WorkManager consome bateria (mas minimamente)
- **iOS**: Pode ter restrições em background tasks

## 🚀 Configuração

### 1. Dependências
```yaml
dependencies:
  workmanager: ^0.5.2  # Já adicionado
```

### 2. Android Configuration
Adicione ao `android/app/src/main/AndroidManifest.xml`:
```xml
<application>
    <!-- WorkManager -->
    <provider
        android:name="androidx.startup.InitializationProvider"
        android:authorities="${applicationId}.androidx-startup"
        android:exported="false"
        tools:node="merge">
        <meta-data
            android:name="androidx.work.WorkManagerInitializer"
            android:value="androidx.startup"
            tools:node="remove" />
    </provider>
</application>
```

### 3. iOS Configuration
Adicione ao `ios/Runner/Info.plist`:
```xml
<dict>
    <key>UIBackgroundModes</key>
    <array>
        <string>processing</string>
    </array>
</dict>
```

## 🔧 Personalização

### Alterar Frequência de Verificação
No `notification_service.dart`, mude:
```dart
frequency: const Duration(minutes: 15), // Mude para o intervalo desejado
```

### Personalizar Notificações
Modifique `_checkPendingNotifications()` para:
- Alterar mensagem
- Mudar frequência
- Adicionar condições específicas

## 🧪 Testando

1. **Favoritar anúncio** de outra conta
2. **Fechar o app** completamente
3. **Esperar 15 minutos** (ou menos se alterar frequência)
4. **Verificar**: Notificação deve aparecer na barra do sistema

## 📊 Monitoramento

As notificações são armazenadas na tabela `notificacoes` do Supabase, então você pode:
- Ver todas as notificações enviadas
- Acompanhar taxa de abertura
- Analisar padrões de uso

## 🔄 Alternativas Futuras

Se precisar de notificações instantâneas, considere:
- **OneSignal**: Serviço de push notifications gratuito
- **Firebase**: Se mudar de ideia sobre Firebase
- **WebSockets**: Para notificações em tempo real quando online