import 'dart:async';
import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ImitateGameController(),
      child: MaterialApp(
        title: 'Imitate',
        theme: ThemeData(
          brightness: Brightness.dark,
          textTheme: Typography.englishLike2018,
          splashFactory: InkRipple.splashFactory,
        ),
        home: ImitateGameScreen(),
      ),
    );
  }
}

class ImitateGameScreen extends StatefulWidget {
  @override
  _ImitateGameScreenState createState() => _ImitateGameScreenState();
}

class _ImitateGameScreenState extends State<ImitateGameScreen> {
  @override
  void initState() {
    super.initState();
    _startGame();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _startGame() async {
    await Future.delayed(Duration(seconds: 1));
    Provider.of<ImitateGameController>(context, listen: false).startGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ScoreIndicator(),
            ArrowSequenceCarousel(),
            SizedBox(height: 16),
            ControlPad(),
          ],
        ),
      ),
    );
  }
}

class ControlPad extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final game = Provider.of<ImitateGameController>(context);

    return Material(
      type: MaterialType.circle,
      color: Colors.grey.shade900,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      elevation: 2,
      child: Container(
        width: 240,
        height: 240,
        padding: EdgeInsets.all(8),
        child: IgnorePointer(
          ignoring: game.state != GameState.playerTurn,
          child: Stack(
            children: _buildArrowButtons(game),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildArrowButtons(ImitateGameController game) {
    int i = 0;
    return Arrow.values.map((arrow) {
      return Align(
        alignment: [
          Alignment.topCenter,
          Alignment.centerLeft,
          Alignment.bottomCenter,
          Alignment.centerRight
        ][i++],
        child: IconButton(
          icon: Icon(arrow.icon),
          iconSize: 60,
          color: arrow.color,
          onPressed: () {
            game.acceptInput(arrow);
          },
        ),
      );
    }).toList();
  }
}

class ScoreIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final game = Provider.of<ImitateGameController>(context);

    final score = game.state == GameState.computerTurn
        ? game.showingIndex
        : game.playerArrows.length;
    return InkWell(
      onTap: () {
        game.startGame();
      },
      child: Column(
        children: [
          Text('$score', style: textTheme.headline3),
          Text(game.state.toString()),
        ],
      ),
    );
  }
}

class ArrowSequenceCarousel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final game = Provider.of<ImitateGameController>(context);
    return IgnorePointer(
      ignoring: true,
      // Somehow AnimatedCrossFade and SnimatedSwitcher
      // doesn't work well according to intended needs.
      child: Stack(
        children: [
          AnimatedOpacity(
            opacity:
                game.state == GameState.computerTurn && game.showingIndex > 0
                    ? 1
                    : 0,
            duration: mediumAnimDuration,
            child: _buildArrows(
                game.generatedArrows, game.showingIndex, game.state),
          ),
          AnimatedOpacity(
            opacity: game.state != GameState.computerTurn &&
                    game.playerArrows.length > 0
                ? 1
                : 0,
            duration: mediumAnimDuration,
            child: _buildArrows(
                game.playerArrows, game.playerArrows.length, game.state),
          ),
        ],
      ),
    );
  }

  Widget _buildArrows(List<Arrow> arrows, int index, GameState state) {
    final _carousel = CarouselSlider.builder(
      height: 72,
      scrollPhysics: BouncingScrollPhysics(),
      itemCount: index,
      itemBuilder: (context, index) {
        final arrow = arrows[index];
        if (state == GameState.ended && index == arrows.length - 1) {
          return CircleAvatar(
            child: Icon(arrow.icon, size: 60),
            backgroundColor: Colors.red,
            foregroundColor: Colors.black,
            radius: 32,
          );
        } else {
          return Icon(arrow.icon, size: 60, color: arrow.color);
        }
      },
      viewportFraction: 0.2,
      enableInfiniteScroll: false,
    );
    _scrollToLatest(_carousel, index);
    return _carousel;
  }

  void _scrollToLatest(CarouselSlider carousel, int index) async {
    await Future.delayed(Duration(milliseconds: 10));
    carousel?.animateToPage(index < 1 ? 0 : index - 1,
        duration: mediumAnimDuration, curve: Curves.easeOutBack);
  }
}

class ImitateGameController extends ChangeNotifier {
  final generatedArrows = <Arrow>[];
  final playerArrows = <Arrow>[];

  final random = Random();

  GameState _state = GameState.idle;
  int _showingIndex = 0;

  Timer _autoScrollTimer;

  GameState get state => _state;

  int get showingIndex => _showingIndex;

  int get length => generatedArrows.length;

  void startGame() {
    resetArrowList();
    _computerTurn();
  }

  void _computerTurn() {
    _state = GameState.computerTurn;
    _showingIndex = 0;
    notifyListeners();
    addNewRandomArrow();
    setAutoScrollTimer();
  }

  void _playerTurn() {
    _state = GameState.playerTurn;
    playerArrows.clear();
    notifyListeners();
  }

  void _endGame() {
    _state = GameState.ended;
    notifyListeners();
  }

  void setAutoScrollTimer() {
    _autoScrollTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _showingIndex++;
      if (_showingIndex > generatedArrows.length) {
        timer.cancel();
        _showingIndex--;
        _playerTurn();
      }
      notifyListeners();
    });
  }

  void addNewRandomArrow() {
    generatedArrows.add(_generateNewArrow());
  }

  void addNewArrow(Arrow arrow) {
    generatedArrows.add(arrow);
    notifyListeners();
  }

  void resetArrowList() {
    generatedArrows.clear();
    playerArrows.clear();
    _showingIndex = 0;
    notifyListeners();
  }

  Arrow _generateNewArrow() {
    return Arrow.values[random.nextInt(Arrow.values.length)];
  }

  void acceptInput(Arrow arrowFromInput) {
    if (_state != GameState.playerTurn) return;
    final correctArrow = generatedArrows[playerArrows.length];
    if (correctArrow == arrowFromInput) {
      playerArrows.add(arrowFromInput);
      if (generatedArrows.length == playerArrows.length) {
        HapticFeedback.mediumImpact();
        Future.delayed(Duration(seconds: 1), _computerTurn);
      }
    } else {
      playerArrows.add(arrowFromInput);
      _endGame();
    }
    notifyListeners();
  }
}

class Arrow {
  const Arrow(this.color, this.icon);

  final Color color;
  final IconData icon;

  static const values = [up, left, down, right];

  static const up = Arrow(Colors.redAccent, Icons.arrow_upward);
  static const left = Arrow(Colors.yellowAccent, Icons.arrow_back);
  static const down = Arrow(Colors.blueAccent, Icons.arrow_downward);
  static const right = Arrow(Colors.greenAccent, Icons.arrow_forward);
}

enum GameState {
  idle,
  computerTurn,
  playerTurn,
  ended,
}

const mediumAnimDuration = Duration(milliseconds: 300);
