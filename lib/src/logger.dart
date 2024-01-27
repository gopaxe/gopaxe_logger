import 'package:encrypt/encrypt.dart';
import 'package:gopaxe_logger/src/logs_format/logs_format.dart';
import 'package:loggme/loggme.dart';

class _EnvChannelsConfigs {
  final List<SlackChannelSender> prodSlackSenders;
  final List<SlackChannelSender> devSlackSenders;
  final List<TelegramChannelSender> prodTelegramSenders;
  final List<TelegramChannelSender> devTelegramSenders;

  _EnvChannelsConfigs(
      {required this.devSlackSenders,
      required this.devTelegramSenders,
      required this.prodSlackSenders,
      required this.prodTelegramSenders});
}

class _ChannelsConfigs {
  final _EnvChannelsConfigs appsSenders;
  final _EnvChannelsConfigs serverSenders;
  _ChannelsConfigs({required this.appsSenders, required this.serverSenders});
}

enum GopaxeLoggerEnv { dev, prod }

enum GopaxeApplicationName {
  worker('Gopaxe Artisan'),
  client('Gopaxe Client'),
  admin('Gopaxe Admin'),
  server('Gopaxe API Server');

  const GopaxeApplicationName(this.name);
  final String name;
}

class GopaxeLogger {
  final GopaxeApplicationName _applicationName;
  final GopaxeLoggerEnv _env;
  final _ChannelsConfigs _configs;
  Logger? _devAppsLogger;
  Logger? _devServerLogger;
  Logger? _prodAppsLogger;
  Logger? _prodServerLogger;

  GopaxeLogger(this._applicationName, this._env, String secret)
      : _configs = GopaxeLogger._getChannelsConfigs(secret) {
    _init();
  }

  void _init() {
    final loggers = GopaxeLogger._initLoggers(
      _configs,
    );

    _devAppsLogger = loggers[0];
    _devServerLogger = loggers[1];
    _prodAppsLogger = loggers[2];
    _prodServerLogger = loggers[3];
  }

  GopaxeLogger.asWorkerApp(String secretKey, this._env)
      : _applicationName = GopaxeApplicationName.worker,
        _configs = GopaxeLogger._getChannelsConfigs(secretKey) {
    _init();
  }

  GopaxeLogger.asClientApp(String secretKey, this._env)
      : _applicationName = GopaxeApplicationName.client,
        _configs = GopaxeLogger._getChannelsConfigs(secretKey) {
    _init();
  }

  GopaxeLogger.asAdminApp(String secretKey, this._env)
      : _applicationName = GopaxeApplicationName.admin,
        _configs = GopaxeLogger._getChannelsConfigs(secretKey) {
    _init();
  }

  GopaxeLogger.asAPIServer(String secretKey, this._env)
      : _applicationName = GopaxeApplicationName.server,
        _configs = GopaxeLogger._getChannelsConfigs(secretKey) {
    _init();
  }

  void logMe(SendAsLog log) {
    if (_applicationName == GopaxeApplicationName.server) {
      _logServerError(log);
    } else {
      _logAppError(log);
    }
  }

  _logServerError(SendAsLog log) {
    _env == GopaxeLoggerEnv.dev
        ? _logErrorForDevServer(log)
        : _logErrorForProdServer(log);
  }

  _logAppError(SendAsLog log) {
    _env == GopaxeLoggerEnv.dev
        ? _logErrorForDevApp(log)
        : _logErrorForProdApp(log);
  }

  /// Send logs on Dev Apps channels
  _logErrorForDevApp(SendAsLog log) async {
    final (slackLog, telegramLog) = log.toLog(_applicationName);
    _devAppsLogger!
        .logs(slackLoggMessage: slackLog, telegramLoggMessage: telegramLog);
  }

  /// Send logs on Prod Apps channels
  _logErrorForProdApp(SendAsLog log) async {
    final (slackLog, telegramLog) = log.toLog(_applicationName);
    _prodAppsLogger!
        .logs(slackLoggMessage: slackLog, telegramLoggMessage: telegramLog);
  }

  /// Send logs on Prod Server channel
  _logErrorForProdServer(SendAsLog log) async {
    final (slackLog, telegramLog) = log.toLog(_applicationName);
    _prodServerLogger!
        .logs(slackLoggMessage: slackLog, telegramLoggMessage: telegramLog);
  }

  /// Send logs on Dev Server channel
  _logErrorForDevServer(SendAsLog log) async {
    final (slackLog, telegramLog) = log.toLog(_applicationName);
    return _devServerLogger!
        .logs(slackLoggMessage: slackLog, telegramLoggMessage: telegramLog);
  }

  static List<Logger> _initLoggers(_ChannelsConfigs configs) {
    final devAppsLogger = Logger(
        slackChannelsSenders: configs.appsSenders.devSlackSenders,
        telegramChannelsSenders: configs.appsSenders.devTelegramSenders);

    final devServerLogger = Logger(
        slackChannelsSenders: configs.serverSenders.devSlackSenders,
        telegramChannelsSenders: configs.serverSenders.devTelegramSenders);

    final prodAppsLogger = Logger(
        slackChannelsSenders: configs.appsSenders.prodSlackSenders,
        telegramChannelsSenders: configs.appsSenders.prodTelegramSenders);

    final prodServerLogger = Logger(
        slackChannelsSenders: configs.serverSenders.prodSlackSenders,
        telegramChannelsSenders: configs.serverSenders.prodTelegramSenders);

    return [devAppsLogger, devServerLogger, prodAppsLogger, prodServerLogger];
  }

  static _ChannelsConfigs _getChannelsConfigs(String secret) {
    try {
      final encryptedSlackToken =
          "LJzI4PuR19rb0lYakw9I28zFfsoYUo1/msFirk/ksa8sws8AeqVmHsGjIyZmwT4yRoduUR+NEGHYp0Hu1dA07Q==";

      final encryptedTelegramToken =
          "YsGHt+CR0tvc11Ri63owko3cKbFsL+0phoUz9A3q9chx//1CV7ZIDOOUClBBqAl+";

      final iv =
          IV.fromUtf8("NFKp'ESl'h0=#FUm9]YMt!H0NAF,=F7+".substring(0, 6));

      final encrypter = Encrypter(AES(Key.fromUtf8(secret)));

      final slackApplicationToken =
          encrypter.decrypt64(encryptedSlackToken, iv: iv);
      final telegramApplicationToken =
          encrypter.decrypt64(encryptedTelegramToken, iv: iv);

      final slackDevAppLogsName =
          encrypter.decrypt64('MJbGr7fXlJzFiAFE2T984Q==', iv: iv);
      final slackDevServerLogsName =
          encrypter.decrypt64('MJbGr6XClpmNlkNPxVsM4w==', iv: iv);

      final slackProdAppLogsName =
          encrypter.decrypt64('JIHf5vvGlJ+byQJMzU994A==', iv: iv);
      final slackProdServerLogsName = encrypter
          .decrypt64('JIHf5vvUgZ2egRwOxlMYkenhQ+w7d6Rau+FKjGrCkYs=', iv: iv);

      final telegramChatId =
          encrypter.decrypt64('ecKAsuee1tvf01kQmA994A==', iv: iv);

      final telegramDevAppLogsThread =
          encrypter.decrypt64('bcaGstqr6OPk6GIvpjBz7g==', iv: iv);
      final telegramDevServerLogsThread =
          encrypter.decrypt64('bcaGsNqr6OPk6GIvpjBz7g==', iv: iv);

      final telegramProdAppLogsThread =
          encrypter.decrypt64('bcaGttqr6OPk6GIvpjBz7g==', iv: iv);
      final telegramProdServerLogsThread =
          encrypter.decrypt64('bcaGtNqr6OPk6GIvpjBz7g==', iv: iv);

      return _ChannelsConfigs(
          appsSenders: _EnvChannelsConfigs(devSlackSenders: [
            SlackChannelSender(
                applicationToken: slackApplicationToken,
                channelName: slackDevAppLogsName)
          ], devTelegramSenders: [
            TelegramChannelSender(
                botId: telegramApplicationToken,
                chatId: telegramChatId,
                messageThreadId: telegramDevAppLogsThread)
          ], prodSlackSenders: [
            SlackChannelSender(
                applicationToken: slackApplicationToken,
                channelName: slackProdAppLogsName)
          ], prodTelegramSenders: [
            TelegramChannelSender(
                botId: telegramApplicationToken,
                chatId: telegramChatId,
                messageThreadId: telegramProdAppLogsThread)
          ]),
          serverSenders: _EnvChannelsConfigs(devSlackSenders: [
            SlackChannelSender(
                applicationToken: slackApplicationToken,
                channelName: slackDevServerLogsName)
          ], devTelegramSenders: [
            TelegramChannelSender(
                botId: telegramApplicationToken,
                chatId: telegramChatId,
                messageThreadId: telegramDevServerLogsThread)
          ], prodSlackSenders: [
            SlackChannelSender(
                applicationToken: slackApplicationToken,
                channelName: slackProdServerLogsName)
          ], prodTelegramSenders: [
            TelegramChannelSender(
                botId: telegramApplicationToken,
                chatId: telegramChatId,
                messageThreadId: telegramProdServerLogsThread)
          ]));
    } catch (_) {
      rethrow;
    }
  }
}
