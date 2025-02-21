import 'package:loggy/loggy.dart';

mixin VdbLogger implements LoggyType {
  @override
  Loggy<VdbLogger> get loggy => Loggy<VdbLogger>(runtimeType.toString().padRight(30));
}
