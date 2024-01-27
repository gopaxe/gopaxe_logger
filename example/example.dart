import 'package:gopaxe_logger/gopaxe_logger.dart';

void main(List<String> args) {
  final gopaxeLogger =
      GopaxeLogger.asAPIServer("<SECRET_KEY_HERE>", GopaxeLoggerEnv.dev);

  try {
    throw Exception(
        'Welcome !! To the official Logger of Gopaxe build by Ofceab Studio.\nBy this tools, will get logs of any apps. Remember : LOGS are GOLD');
  } catch (e, stackTrace) {
    gopaxeLogger.logMe(LogsErrorFormat(
        errorName: e.toString(), stackTrace: stackTrace.toString()));
  }
}
