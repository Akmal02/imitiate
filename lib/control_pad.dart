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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:imitate/game_controller.dart';
import 'package:provider/provider.dart';
import 'arrow.dart';
import 'arrow_button.dart';
import 'main.dart';

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
        child: ArrowButton(
          size: size,
          highlighted: arrow == latestArrow,
          arrow: arrow,
          highlightPulseDuration: game.waitingTime * 0.7,
          onTap: () {
            if (game.state == GameState.ended)
              game.resetGame();
            else
              game.acceptInput(arrow);
          },
        ),
      );
    }).toList();
  }
}
