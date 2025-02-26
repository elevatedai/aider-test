import 'package:file_browser/features/connections/data/models/connection_model.dart';
import 'package:file_browser/features/file_browser/data/repositories/local_repository.dart';
import 'package:file_browser/features/file_browser/data/repositories/webdav_repository.dart';
import 'package:file_browser/features/file_browser/domain/repositories/file_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A provider for the active connection ID
final activeConnectionProvider = StateProvider<String?>((ref) => null);

// A provider that exposes the current repository based on active connection
final currentRepositoryProvider = Provider<FileRepository>((ref) {
  final activeConnectionId = ref.watch(activeConnectionProvider);
  final connections = ref.watch(connectionsProvider);
  
  if (activeConnectionId == null || connections.isEmpty) {
    // Default to local if no active connection
    return LocalRepository();
  }
  
  final activeConnection = connections.firstWhere(
    (conn) => conn.id == activeConnectionId,
    orElse: () => connections.first,
  );
  
  switch (activeConnection.type) {
    case ConnectionType.webdav:
      return WebDavRepository(
        baseUrl: activeConnection.host,
        username: activeConnection.username,
        password: activeConnection.password,
      );
    case ConnectionType.local:
      return LocalRepository();
  }
});

class ConnectionsNotifier extends StateNotifier<List<ConnectionModel>> {
  ConnectionsNotifier() : super([]) {
    _loadConnections();
  }
  
  final _secureStorage = const FlutterSecureStorage();
  
  Future<void> _loadConnections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final connectionIds = prefs.getStringList('connectionIds') ?? [];
      
      final connections = <ConnectionModel>[];
      for (final id in connectionIds) {
        final type = prefs.getInt('connection_$id\_type') ?? 0;
        final name = prefs.getString('connection_$id\_name') ?? '';
        final host = prefs.getString('connection_$id\_host') ?? '';
        final port = prefs.getInt('connection_$id\_port');
        final path = prefs.getString('connection_$id\_path') ?? '/';
        
        // Get credentials from secure storage
        final username = await _secureStorage.read(key: 'connection_$id\_username') ?? '';
        final password = await _secureStorage.read(key: 'connection_$id\_password') ?? '';
        
        connections.add(ConnectionModel(
          id: id,
          name: name,
          type: ConnectionType.values[type],
          host: host,
          port: port,
          username: username,
          password: password,
          path: path,
        ));
      }
      
      state = connections;
      
      // If we have at least one connection and no active connection,
      // set the first one as active
      if (connections.isNotEmpty) {
        // Add a local connection if none exists
        if (!connections.any((conn) => conn.type == ConnectionType.local)) {
          await addConnection(ConnectionModel(
            id: 'local',
            name: 'Local Storage',
            type: ConnectionType.local,
            host: '',
            username: '',
            password: '',
          ));
        }
      }
    } catch (e) {
      debugPrint('Error loading connections: $e');
    }
  }
  
  Future<void> _saveConnections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final connectionIds = state.map((conn) => conn.id).toList();
      
      await prefs.setStringList('connectionIds', connectionIds);
      
      for (final connection in state) {
        await prefs.setInt('connection_${connection.id}\_type', connection.type.index);
        await prefs.setString('connection_${connection.id}\_name', connection.name);
        await prefs.setString('connection_${connection.id}\_host', connection.host);
        if (connection.port != null) {
          await prefs.setInt('connection_${connection.id}\_port', connection.port!);
        }
        await prefs.setString('connection_${connection.id}\_path', connection.path);
        
        // Save credentials to secure storage
        await _secureStorage.write(
          key: 'connection_${connection.id}\_username',
          value: connection.username,
        );
        await _secureStorage.write(
          key: 'connection_${connection.id}\_password',
          value: connection.password,
        );
      }
    } catch (e) {
      debugPrint('Error saving connections: $e');
    }
  }
  
  Future<void> addConnection(ConnectionModel connection) async {
    state = [...state, connection];
    await _saveConnections();
  }
  
  Future<void> updateConnection(ConnectionModel connection) async {
    state = [
      for (final conn in state)
        if (conn.id == connection.id) connection else conn
    ];
    await _saveConnections();
  }
  
  Future<void> removeConnection(String connectionId) async {
    state = state.where((conn) => conn.id != connectionId).toList();
    await _saveConnections();
    
    // Clean up stored credentials
    await _secureStorage.delete(key: 'connection_${connectionId}\_username');
    await _secureStorage.delete(key: 'connection_${connectionId}\_password');
  }
  
  Future<bool> connectTo(String connectionId) async {
    try {
      final connection = state.firstWhere(
        (conn) => conn.id == connectionId,
        orElse: () => throw FileOperationException('Connection not found'),
      );
      
      FileRepository repository;
      
      switch (connection.type) {
        case ConnectionType.webdav:
          if (!connection.host.startsWith('http://') && !connection.host.startsWith('https://')) {
            throw FileOperationException('WebDAV URL must start with http:// or https://');
          }
          if (connection.host.isEmpty) {
            throw FileOperationException('Host cannot be empty');
          }
          repository = WebDavRepository(
            baseUrl: connection.host,
            username: connection.username,
            password: connection.password,
          );
          break;
        case ConnectionType.local:
          repository = LocalRepository();
          break;
      }
      
      final connected = await repository.connect();
      
      if (connected) {
        container.read(activeConnectionProvider.notifier).state = connectionId;
        return true;
      }
      
      return false;
    } on FileOperationException catch (e) {
      rethrow;
    } catch (e) {
      throw FileOperationException('Failed to establish connection', e);
    }
  }
  
  late ProviderContainer container;
}

final connectionsProvider = StateNotifierProvider<ConnectionsNotifier, List<ConnectionModel>>((ref) {
  final notifier = ConnectionsNotifier();
  notifier.container = ref.container;
  return notifier;
});
