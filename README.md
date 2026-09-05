Instale as dependências:

Bash
flutter pub get
Execute o projeto (via emulador ou dispositivo físico):

Bash
flutter run
🛠 Stack Escolhida
Framework: Flutter (v3.47+)

Linguagem: Dart

Build System Nativo: Kotlin DSL (Gradle 9.3.1 / AGP 8.11.1)

Design Pattern de UI: Material 3 / Dark Mode nativo.

🏗 Arquitetura Utilizada
Para o escopo de um MVP de 4 dias, optei por uma arquitetura focada no princípio KISS (Keep It Simple, Stupid).
O aplicativo utiliza StatefulWidgets bem delimitados para o controle de estado da interface e injeção direta de repositórios locais para armazenamento. A estrutura foi construída pensando em componentização (Clean Code), separando visualmente a navegação, o motor do relógio e as lógicas de CRUD de refeições, facilitando uma futura refatoração para camadas mais profundas.

💡 Decisões Técnicas
Timer Resiliente (Sem Isolate/Background Services Pesados):
Em vez de forçar um serviço rodando em segundo plano (que consome bateria e é frequentemente derrubado pelo SO do Android/iOS), o timer é determinístico. Ele salva o timestamp exato (DateTime.now()) no cache. Se o usuário fechar o app e reabrir horas depois, o sistema recalcula o delta de tempo transcorrido matematicamente, simulando um funcionamento perfeito em background de forma super leve.

Notificações Locais:
Implementadas diretamente no dispositivo utilizando o flutter_local_notifications para avisos de início e encerramento de jejum, criando engajamento real sem depender de backend.

UX Responsiva e Câmera Local (Offline-First):
A interface foi encapsulada com limites de largura (ConstrainedBox) para manter a elegância e não quebrar o layout caso o usuário vire o dispositivo (Landscape) ou use um Tablet. Adicionalmente, foi incluído o recurso de tirar fotos das refeições processando e salvando a imagem localmente no dispositivo.

📚 Bibliotecas Utilizadas
shared_preferences: ^2.2.3 (Motor de persistência de dados em cache, sessões e logs numéricos).

flutter_local_notifications: ^17.0.0 (Disparo de alertas em background).

image_picker: ^1.1.2 (Acesso nativo à câmera do dispositivo para o registro visual das refeições).

⚖️ Trade-offs Considerados
StatefulWidget vs Clean Architecture (BLoC/MVVM):
Embora a Clean Architecture associada ao BLoC seja o padrão ouro para manutenção e testes, adotá-la num prazo tão curto poderia atrasar a entrega das core features (Timer e Métricas). Optei por focar primeiro na estabilidade nativa e garantir um aplicativo livre de bugs (um produto real), centralizando o estado nas próprias telas.

SharedPreferences vs SQLite/Hive:
Como o MVP exige apenas o armazenamento de sessões (Strings), horários (DateTime) e JSONs leves de histórico diário, o shared_preferences atendeu com extrema velocidade. Um banco de dados relacional (SQLite) adicionaria um overhead de migrations desnecessário nesta fase inicial do produto.

🔮 O que melhoraria com mais tempo
Refatoração Estrutural: Migrar a gestão de estado para BLoC (Business Logic Component), separando o motor de cálculo matemático do timer e a lógica de negócio completamente da camada de UI (Presentation Layer).

Persistência Avançada (Hive/Isar): Implementar um banco de dados NoSQL rápido (como Hive) para criar tipagem forte (TypeAdapters) nas Entidades de Refeição e Histórico, permitindo queries complexas por períodos (ex: filtrar refeições de meses anteriores).

Testes Automatizados: Adicionar testes unitários (flutter_test) na lógica de cálculo de horas e parseamento de DateTime, garantindo a integridade dos gráficos semanais em pipelines de CI/CD.

⏱ Tempo gasto no desafio: ~4 dias corridos (incluindo troubleshooting de configurações nativas Gradle/Android, implementação offline-first e refino de UX).

Desenvolvido por Lécio Ferreira Guimarães.