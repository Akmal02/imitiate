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

import 'arrow.dart';

class ArrowButton extends StatefulWidget {
  const ArrowButton({
    Key key,
    @required this.arrow,
    this.highlighted = false,
    @required this.highlightPulseDuration,
    @required this.size,
    @required this.onTap,
  }) : super(key: key);

  final Arrow arrow;
  final bool highlighted;
  final Duration highlightPulseDuration;
  final double size;
  final VoidCallback onTap;

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
    return GestureDetector(
      onTapDown: (_) => widget.onTap(),
      onTapUp: (_) async {
        await Future.delayed(Duration(milliseconds: 200));
        setState(() {
          highlighted = false;
        });
      },
      child: AnimatedOpacity(
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
      ),
    );
  }
}
