import 'package:flutter/material.dart';
import 'dart:developer' as developer;

/// Error boundary widget that catches widget build errors
/// Displays error UI instead of crashing the app
/// Requirements: 10.1
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails)? errorBuilder;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _errorDetails;

  @override
  void initState() {
    super.initState();
    // Set up error handler
    FlutterError.onError = (FlutterErrorDetails details) {
      // Log error for debugging
      developer.log(
        'Widget build error',
        error: details.exception,
        stackTrace: details.stack,
        name: 'ErrorBoundary',
      );

      // Update state to show error UI
      if (mounted) {
        setState(() {
          _errorDetails = details;
        });
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_errorDetails != null) {
      // Show custom error builder or default error UI
      return widget.errorBuilder?.call(_errorDetails!) ??
          _buildDefaultErrorUI(context);
    }

    // Return the child widget
    return widget.child;
  }

  Widget _buildDefaultErrorUI(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 24),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'An unexpected error occurred. Please restart the app.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Clear error and try to rebuild
                  setState(() {
                    _errorDetails = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
