// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

import 'package:flutter/services.dart';
import 'package:ultralytics_yolo/models/yolo_exceptions.dart';
import 'logger_manager.dart';

/// Centralized error handling utility for YOLO operations.
///
/// This class provides a unified way to handle PlatformExceptions and convert
/// them to appropriate YOLO-specific exceptions.
class YOLOErrorHandler {
  /// Handles PlatformExceptions and converts them to appropriate YOLO exceptions.
  ///
  /// [e] The PlatformException to handle
  /// [context] Optional context string for more specific error messages
  ///
  /// Returns the appropriate YOLOException based on the error code
  static YOLOException handlePlatformException(
    PlatformException e, {
    String? context,
  }) {
    final contextPrefix = context != null ? '$context: ' : '';

    logger.e('PlatformException occurred: ${e.code}', error: e, stackTrace: StackTrace.current);

    switch (e.code) {
      case 'MODEL_NOT_FOUND':
        logger.e('Model not found: ${e.message}', error: e);
        return ModelLoadingException(
          '${contextPrefix}Model file not found: ${e.message}',
        );

      case 'INVALID_MODEL':
        logger.e('Invalid model format: ${e.message}', error: e);
        return ModelLoadingException(
          '${contextPrefix}Invalid model format: ${e.message}',
        );

      case 'UNSUPPORTED_TASK':
        String taskName = 'unknown';
        if (context != null && context.contains('task ')) {
          final match = RegExp(r'task (\w+)').firstMatch(context);
          if (match != null) {
            taskName = match.group(1) ?? 'unknown';
          }
        }
        logger.e('Unsupported task type: $taskName', error: e);
        return ModelLoadingException(
          '${contextPrefix}Unsupported task type: $taskName',
        );

      case 'MODEL_FILE_ERROR':
        logger.e('Model file error: ${e.message}', error: e);
        return ModelLoadingException(
          '${contextPrefix}Failed to load model: ${e.message}',
        );

      case 'MODEL_NOT_LOADED':
        logger.e('Model not loaded exception', error: e);
        return ModelNotLoadedException(
          '${contextPrefix}Model has not been loaded. Call loadModel() first.',
        );

      case 'INVALID_IMAGE':
        logger.e('Invalid image format or corrupted image data', error: e);
        return InvalidInputException(
          '${contextPrefix}Invalid image format or corrupted image data',
        );

      case 'IMAGE_LOAD_ERROR':
        logger.e('Image load error: ${e.message}', error: e);
        return InferenceException(
          '${contextPrefix}Platform error during inference: ${e.message}',
        );

      case 'PREDICTION_ERROR':
      case 'prediction_error':
        logger.e('Prediction error: ${e.message}', error: e);
        return InferenceException(
          '${contextPrefix}Prediction failed on native side: ${e.message}',
        );

      case 'INFERENCE_ERROR':
        logger.e('Inference error: ${e.message}', error: e);
        return InferenceException(
          '${contextPrefix}Error during inference: ${e.message}',
        );

      default:
        logger.e('Unknown platform error: ${e.message}', error: e);
        return InferenceException(
          '${contextPrefix}Platform error: ${e.message}',
        );
    }
  }

  /// Handles generic exceptions and wraps them in appropriate YOLO exceptions.
  ///
  /// [e] The generic exception to handle
  /// [context] Optional context string for more specific error messages
  ///
  /// Returns the appropriate YOLOException
  static YOLOException handleGenericException(dynamic e, {String? context}) {
    final contextPrefix = context != null ? '$context: ' : '';

    logger.e('Generic exception occurred: $e', error: e, stackTrace: StackTrace.current);

    if (e is YOLOException) {
      return e;
    }

    if (e.toString().contains('MissingPluginException')) {
      logger.e('MissingPluginException detected in context: ${context ?? "unknown"}', error: e);
      if (context != null && context.contains('load model')) {
        return ModelLoadingException(
          '${contextPrefix}Model loading failed: $e',
        );
      } else if (context != null && context.contains('switch to model')) {
        return ModelLoadingException(
          '${contextPrefix}Model switching failed: $e',
        );
      } else if (context != null && context.contains('predict')) {
        return InferenceException('${contextPrefix}Inference failed: $e');
      }
    }

    logger.e('Unknown generic error: $e', error: e);
    return InferenceException('${contextPrefix}Unknown error: $e');
  }

  /// Handles any exception with a custom context message.
  ///
  /// [e] The exception to handle
  /// [context] The context message describing what operation failed
  static YOLOException handleError(dynamic e, String context) {
    logger.e('Error in context: $context', error: e, stackTrace: StackTrace.current);

    if (e is PlatformException) {
      return handlePlatformException(e, context: context);
    }

    return handleGenericException(e, context: context);
  }
}
