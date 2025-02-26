enum ConnectionType {
  webdav,
  local,
}

class ConnectionModel {
  final String id;
  final String name;
  final ConnectionType type;
  final String host;
  final int? port;
  final String username;
  final String password;
  final String path;

  const ConnectionModel({
    required this.id,
    required this.name,
    required this.type,
    required this.host,
    this.port,
    required this.username,
    required this.password,
    this.path = '/',
  });

  factory ConnectionModel.fromJson(Map<String, dynamic> json) {
    return ConnectionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: ConnectionType.values[json['type'] as int],
      host: json['host'] as String,
      port: json['port'] as int?,
      username: json['username'] as String,
      password: json['password'] as String,
      path: json['path'] as String? ?? '/',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'host': host,
      'port': port,
      'username': username,
      'password': password,
      'path': path,
    };
  }

  ConnectionModel copyWith({
    String? id,
    String? name,
    ConnectionType? type,
    String? host,
    int? port,
    String? username,
    String? password,
    String? path,
  }) {
    return ConnectionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      path: path ?? this.path,
    );
  }
}
