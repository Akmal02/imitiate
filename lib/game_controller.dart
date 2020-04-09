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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'arrow.dart';

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

enum GameState {
  idle,
  computerTurn,
  playerTurn,
  ended,
}
