# Flame
Uma engine de Game para o flutter
Exemplos: https://examples.flame-engine.org/#/

## instalando 
`flutter pub add flame`

## Implementando
Criar uma página principal do jogo, como um `StatefulWidget`

```dart
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_game/Models/the_game.dart';
import 'package:flutter_game/helpers/direction.dart';
import 'package:flutter_game/helpers/joypad.dart';

class MainGamePage extends StatefulWidget {
  const MainGamePage({Key? key}) : super(key: key);

  @override
  MainGameState createState() => MainGameState();
}

class MainGameState extends State<MainGamePage> {
  TheGame game = TheGame();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromRGBO(0, 0, 0, 1),
        body: Stack(
          children: [
            GameWidget(game: game), // render the game
           ...
          ],
        ));
  }
  ...
}
```

## implementando o Game Loop
implementando a classe `TheGame` da página `MainGamePage`, depois disso colocar ná página o `GameWidget` como acima

```dart
import 'package:flame/game.dart';
import 'package:flutter_game/Models/player.dart';

class TheGame extends FlameGame {
  final Player _player = Player();

  @override
  Future<void> onLoad() async {
    add(_player);
  }
}
```

## Implementando o Player
implementando a classe `Player` usada na classe `TheGame` extendendo de um `SpriteComponent` (um componente com imagem) usando o mixin `HasGameRef`, para passar a referência do jogo, eu imagino.

depois disso adicionar o player ao jogo conforme no arquivo acima.

```dart
class Player extends SpriteComponent with HasGameRef {
  Player() : super(size: Vector2.all(50.0));

  @override
  Future<void> onLoad() async {
    super.onLoad();
    sprite = await gameRef.loadSprite('player.png');
    position = gameRef.size / 2;
  }
}

```

`Vector2` para criar um vetor 2D, `.all(50.0)` cria com dimensões de 50 pixel de largura e altura

### adicionando movimento ao personagem

criado um arquivo com o Enum direction:

```dart
enum Direction { up, down, left, right, none }
```

```dart
import 'package:flame/components.dart';
import 'package:flame/geometry.dart';
import 'package:flame/sprite.dart';
import 'package:flutter_game/Models/world_collidable.dart';
import 'package:flutter_game/helpers/direction.dart';

class Player extends SpriteComponent
    with HasGameRef {
  Player() : super(size: Vector2.all(50.0));

  Direction direction = Direction.none;
  final double _playerSpeed = 300.0;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    sprite = await gameRef.loadSprite('player.png');
    position = gameRef.size / 2;
  }

  @override
  void update(double delta) {
    super.update(delta);
    movePlayer(delta);
  }

  void moveUp(double delta) {
    position.add(Vector2(0, delta * -_playerSpeed));
  }

  void moveDown(double delta) {
    position.add(Vector2(0, delta * _playerSpeed));
  }

  void moveLeft(double delta) {
    position.add(Vector2(delta * -_playerSpeed, 0));
  }

  void moveRight(double delta) {
    position.add(Vector2(delta * _playerSpeed, 0));
  }

  void movePlayer(double delta) {
    switch (direction) {
      case Direction.up:
        moveUp(delta);
        break;
      case Direction.down:
        moveDown(delta);
        break;
      case Direction.left:
        moveLeft(delta);
        break;
      case Direction.right:
        moveRight(delta);
        break;
      case Direction.none:
        break;
    }
  }
}
```

no classe que implementa o game, neste caso `the_game.dart`, adicionar o metodo `onJoypadDirectionChanged`, passando assim o direction para a instancia de `Player`, que será ativada da tela de onde é o jogo renderizado:

```dart
class TheGame extends FlameGame {
  final Player _player = Player();

  void onJoypadDirectionChanged(Direction direction) {
    _player.direction = direction;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    await add(_world);
    add(_player);
  }
}
```

ná tela onde é renderizado o jogo, neste caso é `main_game_page.dart`, adicionar o metodo `onJoypadDirectionChanged`, que é passado para o componente `Joypad` que quando acionado irá invocar o metodo de mesmo nome definido na classe `TheGame`

```dart
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_game/Models/the_game.dart';
import 'package:flutter_game/helpers/direction.dart';
import 'package:flutter_game/helpers/joypad.dart';

class MainGamePage extends StatefulWidget {
  const MainGamePage({Key? key}) : super(key: key);

  @override
  MainGameState createState() => MainGameState();
}

class MainGameState extends State<MainGamePage> {
  TheGame game = TheGame();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromRGBO(0, 0, 0, 1),
        body: Stack(
          children: [
            GameWidget(game: game), // render the game
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Joypad(onDirectionChanged: onJoypadDirectionChanged),
              ),
            )
          ],
        ));
  }

  void onJoypadDirectionChanged(Direction direction) {
    game.onJoypadDirectionChanged(direction);
  }
}
```
**NOTA: o componente JoyPad foi criado pelo autor do tutotial e não é o foco do resumo**

### Adicionando animação ao movimento do personagem
É necessário extender a class `Player` de `SpriteAnimationComponent` ao invés de `SpriteComponent`

```dart
import 'package:flame/components.dart';
import 'package:flame/geometry.dart';
import 'package:flame/sprite.dart';
import 'package:flutter_game/Models/world_collidable.dart';
import 'package:flutter_game/helpers/direction.dart';

class Player extends SpriteAnimationComponent
    with HasGameRef {
  Player() : super(size: Vector2.all(50.0));

  Direction direction = Direction.none;
  final double _playerSpeed = 300.0;

  final double _animationSpeed = 0.15;
  late final SpriteAnimation _runDownAnimation;
  late final SpriteAnimation _runLeftAnimation;
  late final SpriteAnimation _runUpAnimation;
  late final SpriteAnimation _runRightAnimation;
  late final SpriteAnimation _standingAnimation;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _loadAnimations().then((_) => {animation = _standingAnimation});
  }

  @override
  void update(double dt) {
    super.update(dt);
    movePlayer(dt);
  }

  Future<void> _loadAnimations() async {
    final spriteSheet = SpriteSheet(
      image: await gameRef.images.load('player_spritesheet.png'),
      srcSize: Vector2(29.0, 32.0),
    );

    _runUpAnimation =
        spriteSheet.createAnimation(row: 2, stepTime: _animationSpeed, to: 4);

    _runDownAnimation =
        spriteSheet.createAnimation(row: 0, stepTime: _animationSpeed, to: 4);

    _runLeftAnimation =
        spriteSheet.createAnimation(row: 1, stepTime: _animationSpeed, to: 4);

    _runRightAnimation =
        spriteSheet.createAnimation(row: 3, stepTime: _animationSpeed, to: 4);

    _standingAnimation =
        spriteSheet.createAnimation(row: 0, stepTime: _animationSpeed, to: 1);
  }

  void moveUp(double delta) {
    position.add(Vector2(0, delta * -_playerSpeed));
  }

  void moveDown(double delta) {
    position.add(Vector2(0, delta * _playerSpeed));
  }

  void moveLeft(double delta) {
    position.add(Vector2(delta * -_playerSpeed, 0));
  }

  void moveRight(double delta) {
    position.add(Vector2(delta * _playerSpeed, 0));
  }

  void movePlayer(double delta) {
    switch (direction) {
      case Direction.up:
        animation = _runUpAnimation;
        moveUp(delta);
        break;
      case Direction.down:
        animation = _runDownAnimation;
        moveDown(delta);
        break;
      case Direction.left:
        animation = _runLeftAnimation;
        moveLeft(delta);
        break;
      case Direction.right:
        animation = _runRightAnimation;
        moveRight(delta);
        break;
      case Direction.none:
        animation = _standingAnimation;
        break;
    }
  }
}

```

## Implementando o ambiente
adicionando o ambiente, por enquanto é sómente uma imagem de fundo

```dart
import 'package:flame/components.dart';

class World extends SpriteComponent with HasGameRef {
  @override
  Future<void>? onLoad() async {
    sprite = await gameRef.loadSprite('rayworld_background.png');
    size = sprite!.originalSize;
    super.onLoad();
  }
}
```
adicionando o ambiente ao jogo, aguardando o carregamento de do ambiente para adicionar o player ao jogo

```dart
class TheGame extends FlameGame {
  final Player _player = Player();
  final World _world = World();

  void onJoypadDirectionChanged(Direction direction) {
    _player.direction = direction;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    await add(_world);
    add(_player);
  }
}
```

### Centralizando o jogador ao ambiente e fazendo com que a camera o acompanhe
no metodo `onLoad` da classe `TheGame`, posiciona o player no centro do mapa, e determina para que a camera siga o personagem, definindo também os limites do ambiente


```dart
class TheGame extends FlameGame with HasCollidables, KeyboardEvents {
  final Player _player = Player();
  final World _world = World();

  void onJoypadDirectionChanged(Direction direction) {
    _player.direction = direction;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    await add(_world);
    add(_player);

    _player.position = _world.size / 2;
    camera.followComponent(
      _player,
      worldBounds: Rect.fromLTRB(0, 0, _world.size.x, _world.size.y),
    );
  }
}
```

### Adicionando colisão com os objetos do ambiente
Como sabemos o ambiente é apenas uma imagem de fundo até então, com alguns desenhos de objetos e áreas que deveriam ser inascesíveis. para determinar por onde o personagem pode andar o projeto tem um `collision_map.json` neste projeto o nome é `rayworld_collision_map.json`
