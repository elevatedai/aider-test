import 'package:file_browser/features/connections/data/models/connection_model.dart';
import 'package:file_browser/features/connections/presentation/providers/connections_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddConnectionScreen extends ConsumerStatefulWidget {
  final ConnectionModel? connection;
  
  const AddConnectionScreen({super.key, this.connection});

  @override
  ConsumerState<AddConnectionScreen> createState() => _AddConnectionScreenState();
}

class _AddConnectionScreenState extends ConsumerState<AddConnectionScreen> {
  final _formKey = GlobalKey<FormState>();
  late ConnectionType _type;
  late final TextEditingController _nameController;
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _pathController;
  bool _obscurePassword = true;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.connection != null;
    
    _type = widget.connection?.type ?? ConnectionType.webdav;
    _nameController = TextEditingController(text: widget.connection?.name ?? '');
    _hostController = TextEditingController(text: widget.connection?.host ?? '');
    _portController = TextEditingController(
      text: widget.connection?.port != null ? widget.connection!.port.toString() : _getDefaultPort(_type)
    );
    _usernameController = TextEditingController(text: widget.connection?.username ?? '');
    _passwordController = TextEditingController(text: widget.connection?.password ?? '');
    _pathController = TextEditingController(text: widget.connection?.path ?? '/');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  String _getDefaultPort(ConnectionType type) {
    switch (type) {
      case ConnectionType.webdav:
        return '443';
      case ConnectionType.local:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Connection' : 'Add Connection'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildConnectionTypeDropdown(),
            const SizedBox(height: 16),
            _buildNameField(),
            const SizedBox(height: 16),
            if (_type != ConnectionType.local) ...[
              _buildHostField(),
              const SizedBox(height: 16),
              _buildPortField(),
              const SizedBox(height: 16),
              _buildUsernameField(),
              const SizedBox(height: 16),
              _buildPasswordField(),
              const SizedBox(height: 16),
              _buildPathField(),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveConnection,
              child: Text(_isEdit ? 'Save Changes' : 'Add Connection'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionTypeDropdown() {
    return DropdownButtonFormField<ConnectionType>(
      value: _type,
      decoration: const InputDecoration(
        labelText: 'Connection Type',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.cloud),
      ),
      items: const [
        DropdownMenuItem(
          value: ConnectionType.webdav,
          child: Text('WebDAV'),
        ),
        DropdownMenuItem(
          value: ConnectionType.local,
          child: Text('Local Storage'),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _type = value;
            _portController.text = _getDefaultPort(value);
          });
        }
      },
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Connection Name',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.label),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a name';
        }
        return null;
      },
    );
  }

  Widget _buildHostField() {
    return TextFormField(
      controller: _hostController,
      decoration: InputDecoration(
        labelText: 'Host',
        hintText: 'example.com',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.dns),
        helperText: _type == ConnectionType.webdav 
            ? 'For WebDAV, include https:// if needed' 
            : null,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a host';
        }
        return null;
      },
    );
  }

  Widget _buildPortField() {
    return TextFormField(
      controller: _portController,
      decoration: const InputDecoration(
        labelText: 'Port',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.sync_alt),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a port number';
        }
        final port = int.tryParse(value);
        if (port == null || port <= 0 || port > 65535) {
          return 'Enter a valid port (1-65535)';
        }
        return null;
      },
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      decoration: const InputDecoration(
        labelText: 'Username',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
      ),
      validator: (value) {
        if (_type != ConnectionType.webdav && _type != ConnectionType.local) {
          if (value == null || value.isEmpty) {
            return 'Please enter a username';
          }
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Password',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
    );
  }

  Widget _buildPathField() {
    return TextFormField(
      controller: _pathController,
      decoration: const InputDecoration(
        labelText: 'Base Path',
        hintText: '/',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.folder),
      ),
    );
  }

  void _saveConnection() {
    if (_formKey.currentState!.validate()) {
      final connection = ConnectionModel(
        id: widget.connection?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        type: _type,
        host: _type != ConnectionType.local ? _hostController.text : '',
        port: _type != ConnectionType.local ? int.parse(_portController.text) : null,
        username: _type != ConnectionType.local ? _usernameController.text : '',
        password: _type != ConnectionType.local ? _passwordController.text : '',
        path: _type != ConnectionType.local ? _pathController.text : '/',
      );
      
      if (_isEdit) {
        ref.read(connectionsProvider.notifier).updateConnection(connection);
      } else {
        ref.read(connectionsProvider.notifier).addConnection(connection);
      }
      
      Navigator.pop(context);
    }
  }
}
