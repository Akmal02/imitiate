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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'game_controller.dart';
import 'main.dart';

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
          Text('Your score is $score', style: textTheme.bodyText1),
          SizedBox(height: 4),
          Text('Tap any button to restart', style: textTheme.caption),
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
