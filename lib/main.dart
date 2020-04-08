/*
 * Copyright (c) 2020 Akmal Muhaimin
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

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
            ControlPad(size: 300),
          ],
        ),
      ),
    );
  }
}

class ControlPad extends StatelessWidget {
  final double size;

  const ControlPad({Key key, @required this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<ImitateGameController>(context);

    return Material(
      type: MaterialType.circle,
      color: Colors.grey.shade900,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      elevation: 2,
      child: Container(
        width: size,
        height: size,
        child: IgnorePointer(
          ignoring: game.state != GameState.playerTurn,
          child: Stack(
            children: _buildArrowButtons(context, game),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildArrowButtons(
      BuildContext context, ImitateGameController game) {
    int i = 0;

    const shift = 1 + sqrt2;

    Arrow latestArrow;
    if (game.state == GameState.computerTurn && game.showingIndex > 0) {
      latestArrow = game.generatedArrows[game.showingIndex - 1];
    } else if (game.state == GameState.playerTurn &&
        game.playerArrows.isNotEmpty) {
      latestArrow = game.playerArrows.last;
    }

    return Arrow.values.map((arrow) {
      return Align(
        alignment: [
          Alignment(0, -shift),
          Alignment(-shift, 0),
          Alignment(0, shift),
          Alignment(shift, 0),
        ][i++],
        child: GestureDetector(
          onTap: () {
            game.acceptInput(arrow);
          },
          child: ArrowButton(
            size: size,
            highlighted: arrow == latestArrow,
            arrow: arrow,
            highlightPulseDuration: game.waitingTime * 0.7,
          ),
        ),
      );
    }).toList();
  }
}

class ArrowButton extends StatefulWidget {
  const ArrowButton({
    Key key,
    @required this.arrow,
    this.highlighted = false,
    @required this.highlightPulseDuration,
    @required this.size,
  }) : super(key: key);

  final Arrow arrow;
  final bool highlighted;
  final Duration highlightPulseDuration;
  final double size;

  @override
  _ArrowButtonState createState() => _ArrowButtonState();
}

class _ArrowButtonState extends State<ArrowButton> {
  bool highlighted = false;

  @override
  void didUpdateWidget(ArrowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlighted) {
      highlighted = true;
      Future.delayed(widget.highlightPulseDuration, () {
        setState(() {
          highlighted = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: highlighted ? 1.0 : 0.3,
      duration: Duration(milliseconds: 200),
      curve: Curves.fastOutSlowIn,
      child: Container(
        decoration: ShapeDecoration(
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(widget.size * 0.25 * sqrt2),
          ),
          color: widget.arrow.color.withOpacity(0.5),
        ),
        width: widget.size * 0.5 * sqrt2,
        height: widget.size * 0.5 * sqrt2,
        child: Icon(widget.arrow.icon, size: 60, color: Colors.white),
      ),
    );
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
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('$score', style: textTheme.headline3),
//          Text(game.state.toString()),
          ],
        ),
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
        duration: mediumAnimDuration, curve: Curves.easeOutCubic);
  }
}

class ImitateGameController extends ChangeNotifier {
  final generatedArrows = <Arrow>[];
  final playerArrows = <Arrow>[];

  final random = Random();

  GameState _state = GameState.idle;
  int _showingIndex = 0;

  Timer _autoScrollTimer;

  Duration waitingTime = Duration(milliseconds: 700);

  GameState get state => _state;

  int get showingIndex => _showingIndex;

  int get length => generatedArrows.length;

  void startGame() {
    _autoScrollTimer?.cancel();
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
    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  void setAutoScrollTimer() {
    _autoScrollTimer = Timer.periodic(waitingTime, (timer) {
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
        HapticFeedback.vibrate();
        Future.delayed(waitingTime, _computerTurn);
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
