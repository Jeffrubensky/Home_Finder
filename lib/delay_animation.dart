// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'dart:async';
import 'welcom_page.dart';

class DelayedAnimation extends StatefulWidget {
  
  final Widget child;
  final int delay;
  const DelayedAnimation({super.key, required this.child, required this.delay});

  @override
  State<DelayedAnimation> createState() => _DelayAnimationState();
}

class _DelayAnimationState extends State<DelayedAnimation> with 
SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animOffset;
  @override
  void initState(){
    super.initState();
    _controller=AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    final curve = CurvedAnimation(
    parent: _controller, 
    curve: Curves.decelerate,);

    _animOffset = Tween<Offset>(
      begin: Offset(0, 10), 
      end: Offset.zero,).animate(curve);

    Timer(Duration(milliseconds: widget.delay), (){
      _controller.forward();

    });

    
  }
  
   @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: SlideTransition(
        position: _animOffset,
        child: widget.child,
        ),
    );
  }
}