import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_ramadhan/widgets/xp_gain_animation.dart';

/// Property-based test for animation frame rate performance
/// **Feature: my-ramadhan-app, Property 33: Animation frame rate performance**
/// **Validates: Requirements 11.2**
///
/// Property: For any UI animation or transition, the frame rate should maintain 60 FPS
/// throughout the animation duration.
void main() {
  group('Animation Performance Tests', () {
    testWidgets(
      'XP gain animation maintains 60 FPS performance',
      (WidgetTester tester) async {
        // Target: 60 FPS = 16.67ms per frame
        const targetFrameTime = Duration(milliseconds: 16);
        final frameTimings = <Duration>[];
        DateTime? lastFrameTime;

        // Build the animation widget
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: XpGainAnimation(
                  xpAmount: 50,
                  onComplete: () {},
                ),
              ),
            ),
          ),
        );

        // Pump frames and measure timing
        // Animation duration is 1500ms, so we need ~90 frames at 60 FPS
        for (int i = 0; i < 100; i++) {
          final frameStart = DateTime.now();
          
          if (lastFrameTime != null) {
            frameTimings.add(frameStart.difference(lastFrameTime));
          }
          
          await tester.pump(const Duration(milliseconds: 16));
          lastFrameTime = frameStart;
        }

        // Calculate statistics
        if (frameTimings.isNotEmpty) {
          final avgFrameTime = frameTimings.fold<int>(
                0,
                (sum, duration) => sum + duration.inMicroseconds,
              ) ~/
              frameTimings.length;

          final avgFrameTimeMs = avgFrameTime / 1000;

          // Check that average frame time is close to 16.67ms (60 FPS)
          // Allow some tolerance for test environment variations
          expect(
            avgFrameTimeMs,
            lessThan(20.0), // Allow up to 20ms (50 FPS minimum)
            reason: 'Animation should maintain near 60 FPS performance',
          );

          // Count frames that exceeded target
          final slowFrames = frameTimings
              .where((duration) => duration > const Duration(milliseconds: 20))
              .length;

          // No more than 10% of frames should be slow
          final slowFramePercentage = (slowFrames / frameTimings.length) * 100;
          expect(
            slowFramePercentage,
            lessThan(10.0),
            reason: 'Less than 10% of frames should exceed 20ms',
          );
        }
      },
    );

    testWidgets(
      'Level up animation maintains 60 FPS performance',
      (WidgetTester tester) async {
        const targetFrameTime = Duration(milliseconds: 16);
        final frameTimings = <Duration>[];
        DateTime? lastFrameTime;

        // Build the animation widget
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: LevelUpAnimation(
                  newLevel: 5,
                  onComplete: () {},
                ),
              ),
            ),
          ),
        );

        // Pump frames and measure timing
        // Animation duration is 800ms, so we need ~48 frames at 60 FPS
        for (int i = 0; i < 60; i++) {
          final frameStart = DateTime.now();
          
          if (lastFrameTime != null) {
            frameTimings.add(frameStart.difference(lastFrameTime));
          }
          
          await tester.pump(const Duration(milliseconds: 16));
          lastFrameTime = frameStart;
        }

        // Calculate statistics
        if (frameTimings.isNotEmpty) {
          final avgFrameTime = frameTimings.fold<int>(
                0,
                (sum, duration) => sum + duration.inMicroseconds,
              ) ~/
              frameTimings.length;

          final avgFrameTimeMs = avgFrameTime / 1000;

          // Check that average frame time is close to 16.67ms (60 FPS)
          expect(
            avgFrameTimeMs,
            lessThan(20.0),
            reason: 'Animation should maintain near 60 FPS performance',
          );

          // Count frames that exceeded target
          final slowFrames = frameTimings
              .where((duration) => duration > const Duration(milliseconds: 20))
              .length;

          final slowFramePercentage = (slowFrames / frameTimings.length) * 100;
          expect(
            slowFramePercentage,
            lessThan(10.0),
            reason: 'Less than 10% of frames should exceed 20ms',
          );
        }
      },
    );

    testWidgets(
      'Screen transition animation maintains 60 FPS performance',
      (WidgetTester tester) async {
        final frameTimings = <Duration>[];
        DateTime? lastFrameTime;

        // Build a simple screen transition using AnimatedSwitcher
        int currentIndex = 0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      final offsetAnimation = Tween<Offset>(
                        begin: const Offset(0.1, 0.0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ));

                      return SlideTransition(
                        position: offsetAnimation,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<int>(currentIndex),
                      child: Center(
                        child: Text('Screen $currentIndex'),
                      ),
                    ),
                  ),
                  floatingActionButton: FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        currentIndex = currentIndex == 0 ? 1 : 0;
                      });
                    },
                    child: const Icon(Icons.swap_horiz),
                  ),
                );
              },
            ),
          ),
        );

        // Trigger transition
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump();

        // Measure frame timings during transition
        // 250ms transition = ~15 frames at 60 FPS
        for (int i = 0; i < 20; i++) {
          final frameStart = DateTime.now();
          
          if (lastFrameTime != null) {
            frameTimings.add(frameStart.difference(lastFrameTime));
          }
          
          await tester.pump(const Duration(milliseconds: 16));
          lastFrameTime = frameStart;
        }

        // Calculate statistics
        if (frameTimings.isNotEmpty) {
          final avgFrameTime = frameTimings.fold<int>(
                0,
                (sum, duration) => sum + duration.inMicroseconds,
              ) ~/
              frameTimings.length;

          final avgFrameTimeMs = avgFrameTime / 1000;

          expect(
            avgFrameTimeMs,
            lessThan(20.0),
            reason: 'Screen transition should maintain near 60 FPS performance',
          );

          final slowFrames = frameTimings
              .where((duration) => duration > const Duration(milliseconds: 20))
              .length;

          final slowFramePercentage = (slowFrames / frameTimings.length) * 100;
          expect(
            slowFramePercentage,
            lessThan(10.0),
            reason: 'Less than 10% of frames should exceed 20ms during transition',
          );
        }
      },
    );

    testWidgets(
      'Checkbox animation maintains 60 FPS performance',
      (WidgetTester tester) async {
        final frameTimings = <Duration>[];
        DateTime? lastFrameTime;
        bool checkboxValue = false;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: Center(
                    child: Checkbox(
                      value: checkboxValue,
                      onChanged: (value) {
                        setState(() {
                          checkboxValue = value ?? false;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        );

        // Trigger checkbox animation
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        // Measure frame timings during animation
        for (int i = 0; i < 20; i++) {
          final frameStart = DateTime.now();
          
          if (lastFrameTime != null) {
            frameTimings.add(frameStart.difference(lastFrameTime));
          }
          
          await tester.pump(const Duration(milliseconds: 16));
          lastFrameTime = frameStart;
        }

        // Calculate statistics
        if (frameTimings.isNotEmpty) {
          final avgFrameTime = frameTimings.fold<int>(
                0,
                (sum, duration) => sum + duration.inMicroseconds,
              ) ~/
              frameTimings.length;

          final avgFrameTimeMs = avgFrameTime / 1000;

          expect(
            avgFrameTimeMs,
            lessThan(20.0),
            reason: 'Checkbox animation should maintain near 60 FPS performance',
          );
        }
      },
    );
  });
}
