# triunvirato_car_marketplace

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Localização (Opcional) e Proximidade
O uso da localização agora é 100% opcional. Nada quebra se o usuário negar.

Quando o usuário toca no botão "Usar minha localização" na tela de publicar anúncio:
1. O app solicita a permissão (apenas nesse momento).
2. Em caso de permissão concedida, preenche automaticamente Cidade e UF.
3. Também guarda `lat` e `lon` no anúncio novo para permitir filtros futuros por distância.

Filtro de proximidade (≈60 km):
- Só é aplicado se TANTO o usuário tiver permitido localização em algum momento (capturando a posição atual) QUANTO o anúncio possuir `lat`/`lon`.
- Se faltar qualquer parte (permissão negada ou anúncio antigo sem coordenadas), o anúncio ainda aparece normalmente (sem exclusão por distância).
- Não há mais tentativa de buscar localização em background automaticamente na lista: é totalmente opt‑in.

### Android
Edite `android/app/src/main/AndroidManifest.xml` e adicione (fora de `<application>`):
```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

### iOS
No arquivo `ios/Runner/Info.plist` inclua:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Usamos sua localização para mostrar anúncios próximos.</string>
```

### Observações
- Campo de cidade e UF sempre editável manualmente (mesmo após auto-preenchimento).
- Se o usuário negar (inclusive "Não perguntar novamente" / deniedForever), basta continuar digitando manualmente.
- Distância configurada: 60 km (função `_haversine` em `comprador_home.dart`).
- Sem coordenadas não há penalidade: listagem permanece completa.
- Futuro (opcional): mover lógica de distância para um RPC ou cálculo server-side usando `earth_distance` / extensões PostGIS (caso ativadas) para escalar melhor.

### Migração Supabase para coordenadas
Execute no SQL editor do Supabase (caso ainda não tenha as colunas):
```sql
alter table veiculos add column if not exists lat double precision;
alter table veiculos add column if not exists lon double precision;
create index if not exists veiculos_lat_lon_idx on veiculos (lat, lon);
```
 Campos são preenchidos somente quando o usuário toca no botão e concede permissão. Anúncios antigos permanecem com `lat`/`lon` nulos e ainda aparecem normalmente.
