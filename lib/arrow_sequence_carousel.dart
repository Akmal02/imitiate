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

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:imitate/game_controller.dart';
import 'package:provider/provider.dart';
import 'arrow.dart';
import 'main.dart';

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
