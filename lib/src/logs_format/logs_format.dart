import 'package:gopaxe_logger/gopaxe_logger.dart';
import 'package:intl/intl.dart';
import 'package:loggme/loggme.dart';

abstract class SendAsLog {
  /// Formatted logs
  (SlackLoggMessage slackLog, TelegramLoggMessage telegramLog) toLog(
      GopaxeApplicationName applicationName);
}

class LogsErrorFormat implements SendAsLog {
  final String errorName;
  final String stackTrace;
  final DateTime dateTime;
  LogsErrorFormat({required this.errorName, required this.stackTrace})
      : dateTime = DateTime.now();

  @override
  (SlackLoggMessage, TelegramLoggMessage) toLog(
      GopaxeApplicationName applicationName) {
    final slackLog = SlackLoggMessage()
      ..addBoldText(applicationName.name)
      ..addNormalText('\n\n')
      ..addBoldText(errorName)
      ..addNormalText('\n\n')
      ..addCodeText(stackTrace)
      ..addNormalText('\n\n')
      ..addItalicText(DateFormat('dd MMM yyyy HH:mm').format(dateTime));

    final telegramLog = TelegramLoggMessage()
      ..addMention("*${applicationName.name}*")
      ..addNormalText('\n\n')
      ..addBoldText(errorName)
      ..addNormalText('\n\n')
      ..addCodeText(stackTrace)
      ..addNormalText('\n\n')
      ..addItalicText(DateFormat('dd MMM yyyy HH:mm').format(dateTime));

    return (slackLog, telegramLog);
  }
}

class LogsRequestSpeedTimeWarning implements SendAsLog {
  final String errorName = 'REQUEST_SPEED_TIME_WARNING';
  final String endpoint;
  final Duration duration;
  final DateTime dateTime;
  LogsRequestSpeedTimeWarning({required this.duration, required this.endpoint})
      : dateTime = DateTime.now();

  @override
  (SlackLoggMessage, TelegramLoggMessage) toLog(
      GopaxeApplicationName applicationName) {
    final slackLog = SlackLoggMessage()
      ..addMention("*${applicationName.name}*")
      ..addNormalText('\n\n')
      ..addBoldText(errorName)
      ..addNormalText('\n\n')
      ..addItalicText('$endpoint :')
      ..addItalicText(duration.inSeconds.toString())
      ..addItalicText(DateFormat('dd MMM yyyy').format(dateTime));

    final telegramLog = TelegramLoggMessage()
      ..addMention("*${applicationName.name}*")
      ..addNormalText('\n\n')
      ..addBoldText(errorName)
      ..addItalicText('$endpoint :')
      ..addItalicText(duration.inSeconds.toString())
      ..addItalicText(DateFormat('dd MMM yyyy').format(dateTime));

    return (slackLog, telegramLog);
  }
}
