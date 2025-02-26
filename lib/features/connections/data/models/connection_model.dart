import 'package:freezed_annotation/freezed_annotation.dart';

part 'connection_model.freezed.dart';
part 'connection_model.g.dart';

enum ConnectionType {
  webdav,
  ftp,
  ftps,
  local,
}

@freezed
class ConnectionModel with _$ConnectionModel {
  const factory ConnectionModel({
    required String id,
    required String name,
    required ConnectionType type,
    required String host,
    int? port,
    required String username,
    required String password,
    @Default('/') String path,
  }) = _ConnectionModel;

  factory ConnectionModel.fromJson(Map<String, dynamic> json) =>
      _$ConnectionModelFromJson(json);
}
