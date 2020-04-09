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
import 'package:flutter/cupertino.dart';
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

class ImitateGameScreen extends StatelessWidget {
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
  final _containerKey = GlobalKey();

  ControlPad({Key key, @required this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<ImitateGameController>(context);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      child: Material(
        type: MaterialType.circle,
        color: Colors.grey.shade900,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        elevation: 2,
        child: AnimatedCrossFade(
          key: _containerKey,
          duration: mediumAnimDuration,
          sizeCurve: Curves.fastOutSlowIn,
          crossFadeState: game.state == GameState.idle
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: _buildPlayButton(context, game),
          secondChild: _buildControlPad(context, game),
        ),
      ),
    );
  }

  Widget _buildPlayButton(BuildContext context, ImitateGameController game) {
    return Container(
      width: size * 0.7,
      height: size * 0.7,
      child: InkWell(
        splashColor: Colors.transparent,
        onTap: game.state == GameState.idle ? () => game.startGame() : null,
        child: Icon(Icons.play_arrow, size: 60),
      ),
    );
  }

  Widget _buildControlPad(BuildContext context, ImitateGameController game) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      child: IgnorePointer(
        ignoring: game.state == GameState.computerTurn,
        child: Stack(
          children: _buildArrowButtons(context, game),
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
          onTapDown: (_) {
            if (game.state == GameState.ended)
              game.resetGame();
            else
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
    final game = Provider.of<ImitateGameController>(context);

    return Container(
      height: 120,
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        transitionBuilder: _buildFadeThroughTransition,
        duration: mediumAnimDuration,
        child: _buildContent(context, game),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ImitateGameController game) {
    final playerSucceed = game.state == GameState.playerTurn &&
        game.playerArrows.length == game.generatedArrows.length;

    final playerFailed = game.state == GameState.ended;

    final gameNotStarted = game.state == GameState.idle;

    final computerFirstTurn =
        game.state == GameState.computerTurn && game.showingIndex == 0;

    final playerFirstTurn =
        game.state == GameState.playerTurn && game.playerArrows.isEmpty;

    final score = game.state == GameState.computerTurn
        ? game.showingIndex
        : game.playerArrows.length;

    final textTheme = Theme.of(context).textTheme;
    final lightText = textTheme.headline4.copyWith(fontWeight: FontWeight.w300);

    if (gameNotStarted) {
      return Text('Imitate', style: lightText.copyWith(letterSpacing: 3));
    } else if (playerSucceed) {
      return Icon(
        Icons.sentiment_very_satisfied,
        size: 56,
        color: Colors.yellow,
      );
    } else if (playerFailed) {
      return Column(
        children: [
          Icon(
            Icons.sentiment_very_dissatisfied,
            size: 56,
            color: Colors.red,
          ),
          SizedBox(height: 8),
          Text('Your score is $score.', style: textTheme.bodyText1),
          SizedBox(height: 4),
          Text('Press any button to restart', style: textTheme.caption),
        ],
      );
    } else if (computerFirstTurn) {
      return Text('Watch!', style: lightText);
    } else if (playerFirstTurn) {
      return Text('Your turn', style: lightText);
    } else {
      return Text('$score',
          style: textTheme.headline3.copyWith(fontWeight: FontWeight.w300));
    }
  }

  Widget _buildFadeThroughTransition(widget, animation) {
    return FadeTransition(
      opacity: CurvedAnimation(
          curve: Interval(0.5, 1, curve: Curves.fastOutSlowIn),
          parent: animation),
      child: widget,
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
      child: Padding(
        padding: EdgeInsets.only(bottom: 24),
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

  Duration waitingTime = Duration(seconds: 1);

  GameState get state => _state;

  int get showingIndex => _showingIndex;

  int get length => generatedArrows.length;

  void startGame() {
    _autoScrollTimer?.cancel();
    resetArrowList();
    _computerTurn();
  }

  void resetGame() {
    _autoScrollTimer?.cancel();
    resetArrowList();
    _state = GameState.idle;
    notifyListeners();
  }

  void _computerTurn() {
    _state = GameState.computerTurn;
    _showingIndex = 0;
    notifyListeners();
    _setTiming();
    _addNewRandomArrow();
    _setAutoScrollTimer();
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

  void _setAutoScrollTimer() {
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

  void _setTiming() {
    final level = generatedArrows.length;
    if (level < 7) {
      waitingTime = Duration(seconds: 1);
    } else if (level < 15) {
      waitingTime = Duration(milliseconds: 700);
    } else if (level < 25) {
      waitingTime = Duration(milliseconds: 500);
    } else {
      waitingTime = Duration(milliseconds: 300);
    }
  }

  void _addNewRandomArrow() {
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
