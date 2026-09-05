Mamba Fast Tracker

O Mamba Fast Tracker é um aplicativo mobile de controle de jejum intermitente e registro calórico diário, desenvolvido integralmente como MVP para o desafio técnico da divisão mobile da Mamba Growth.

O projeto foi construído com foco em qualidade de produção, resiliência de dados (Offline-First) e uma experiência de usuário (UX) fluida e responsiva, simulando um produto pronto para escala comercial.

Demonstração e Execução

Testar via Navegador (Appetize.io): Clique aqui para testar o APK no navegador (COLE_AQUI_SEU_LINK_DO_APPETIZE)
Repositório GitHub: github.com/leciof300/mamba-fast-tracker

Stack Tecnológica

Framework: Flutter (v3.47+)
Linguagem: Dart
Persistência Local: shared_preferences
Notificações Locais: flutter_local_notifications
Mídia Nativa: image_picker (Câmera e Galeria)
Build System Nativo: Kotlin DSL (Gradle 9.3.1 / AGP 8.11.1)

Funcionalidades Entregues

Autenticação Segura: Tela de login com validação estrita de formato de e-mail e persistência local de sessão (AuthGate).

Motor de Jejum Resiliente (Core Feature): Suporte a protocolos pré-definidos (12:12, 16:8, 18:6) e protocolos customizados. O timer opera de forma determinística: se o app for encerrado pelo sistema operacional, os dados de progresso sobrevivem sem perda de estado.

Notificações Nativas: Disparos automáticos locais ao iniciar e concluir ciclos de jejum.

Diário de Refeições com Câmera: Adição, edição e exclusão de refeições com captura de foto integrada direto pelo hardware do dispositivo, processando e salvando os arquivos localmente.

Dashboard de Métricas e Sincronização Diária: Cálculo dinâmico de calorias consumidas versus a meta diária, acompanhado de gráfico de barras evolutivo baseado no histórico real dos últimos 7 dias.

Arquitetura e Decisões Técnicas

Para cumprir o prazo de entrega de um MVP mantendo alta estabilidade, optei por seguir rigorosamente o princípio KISS (Keep It Simple, Stupid):

Gerenciamento de Estado Modular: Utilização de StatefulWidgets altamente coesos e componentizados, promovendo uma separação limpa entre navegação, lógica matemática do relógio e operações de CRUD (Clean Code), o que facilita qualquer refatoração futura para camadas avançadas.

Timer Baseado em Timestamps: Em vez de depender de serviços complexos em segundo plano (background services que drenam bateria e são frequentemente finalizados pelo SO), o app armazena o DateTime.now() exato. O delta temporal é calculado matematicamente ao reabrir a aplicação, garantindo precisão absoluta e baixíssimo consumo de recursos.

UX Responsiva e Offline-First: Toda a interface foi encapsulada com restrições de largura (ConstrainedBox), garantindo que o layout se adapte elegantemente em tablets ou em modo paisagem (Landscape).

Trade-offs Considerados

StatefulWidget vs. Clean Architecture (BLoC / MVVM): Embora arquiteturas em camadas desacopladas sejam o padrão ideal para ecossistemas maduros, introduzi-las em um escopo restrito de MVP traria riscos desnecessários de estabilidade e quebra de build nativo. A escolha consciente por centralizar a lógica garantiu um APK 100% funcional e livre de bugs críticos.

SharedPreferences vs. Bancos Locais (SQLite / Hive): Dado que o escopo exigia salvamento rápido de sessões e pequenos arrays de histórico em JSON, o uso do shared_preferences entregou velocidade de leitura síncrona, eliminando a complexidade de migrações de esquemas (migrations).

O que melhoraria com mais tempo

Migração Arquitetural: Evoluir a gestão de estado para BLoC, isolando completamente as regras de negócio da camada de apresentação.

Camada de Dados Avançada: Adotar uma solução NoSQL como Hive ou Isar com tipagem forte por TypeAdapters.

Testes Automatizados: Implementar testes unitários cobrindo as funções críticas de cálculo de horas e parsing de datas.

Tempo gasto no desafio: ~4 dias corridos (incluindo resolução de configurações nativas Gradle/Kotlin, implementação offline-first e refino de UX).

Como rodar localmente
git clone https://github.com/leciof300/mamba-fast-tracker.git
cd mamba_fast_tracker
flutter pub get
flutter run

Desenvolvido com excelência por Lécio Ferreira Guimarães.
