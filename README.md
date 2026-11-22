# ERounds · Entre Rounds

Jogo 3D de estratégia em que você acompanha uma temporada de boxe como treinador. Os atletas lutam por conta própria. Sua preparação, sua leitura do adversário e seu jeito de conversar mudam a luta e a relação na academia.

## Jogar no navegador

Abra [ERounds no GitHub Pages](https://gcalesi.github.io/ERound/). No celular, gire a tela para a horizontal para ver melhor o ringue e os controles.

## Abrir no Godot

1. Importe `project.godot` no Godot 4.3 ou mais recente.
2. Abra o projeto e pressione **F6** na cena `main.tscn` ou **F5** para executar o jogo.
3. Escolha Caio, Lia ou Bento e planeje a primeira luta.

Também é possível iniciar no terminal com `godot --path .`, a partir da pasta do projeto. O jogo usa o renderizador Compatibility e não requer plug-ins ou downloads de assets.

## Em jogo

- Escolha o treino, a carga e a rotina de alimentação. Os efeitos aparecem no fôlego, no foco, na técnica ou no vínculo.
- Nos momentos de leitura, clique em **Analisar** ou pressione **Espaço**. Você pode orientar imediatamente ou levar sua leitura para a próxima conversa.
- Clique em **Pedir tempo** ou pressione **T** para solicitar a pausa única da liga fictícia. Entre rounds, use até duas ações no córner.
- Converse com seu atleta depois da luta. O vínculo muda com a luta e com o modo como você conduz a conversa. Um atleta que mudar de academia pode voltar como rival na terceira luta.

A carreira salva ao selecionar um atleta, mudar a preparação ou concluir a conversa pós-luta. Uma luta interrompida ao fechar o jogo pode ser reiniciada na tela de preparação.

## Estrutura

| Arquivo | Responsabilidade |
| --- | --- |
| `main.tscn` e `scripts/game.gd` | Cenas da carreira, interface, entradas e som do gongo |
| `scripts/arena.gd` | Ringue, modelos 3D, luzes, câmera e poses |
| `scripts/match.gd` | Simulação da luta, leituras, decisões do córner e placar |
| `scripts/career.gd` | Progressão, relacionamento, rivalidade e salvamento |
| `scripts/roster.gd` | Perfis, planos, preparação e adversários |

## Atualizar a versão web

Com o Godot 4.7.2 e os templates de exportação dessa versão instalados, gere e prepare os arquivos estáticos.

```sh
mkdir -p export/web
godot --headless --export-release Web export/web/index.html
python3 web/prepare-pages.py export/web
```

A branch `gh-pages` publica a raiz. Use os arquivos gerados nela e mantenha os avisos de licença do Godot que já acompanham a versão web.
