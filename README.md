# scheduling_app

A new Flutter project.

## Configuração local

Os arquivos abaixo têm dados do ambiente e ficam fora do Git, então precisam ser
criados em cada clone.

### `dev_config.json`

Copie o modelo e preencha os valores:

```sh
cp dev_config.example.json dev_config.json
```

| Chave | Valor |
| --- | --- |
| `API_URL` | URL da API (repositório `scheduling_api`) |
| `apiKey`, `authDomain`, `projectId`, `storageBucket`, `messagingSenderId`, `appId`, `databaseURL` | Configuração do app no console do Firebase |
| `iosClientId`, `iosBundleId` | Configuração do app iOS no console do Firebase |
| `ENVIRONMENT` | `development` usa `DEFAULT_HOST` no lugar do subdomínio da URL e o caminho `development` no Realtime Database |
| `DEFAULT_HOST` | Subdomínio da empresa usado quando não há subdomínio na URL |

Para executar, use a configuração **Dev** do VS Code ou:

```sh
flutter run --dart-define-from-file=dev_config.json
```

### `android/app/google-services.json`

Obrigatório para compilar no Android. Baixe em **Console do Firebase > Configurações
do projeto > Seus apps**, no app Android `com.example.scheduling_app`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
