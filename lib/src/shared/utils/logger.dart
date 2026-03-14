/// Logger configuration
library;

import 'package:logger/logger.dart';

/// App logger instance
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);

/// Create a logger with custom tag
Logger createLogger(String tag) {
  return Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    output: ConsoleOutput(),
    filter: ProductionFilter(),
  );
}