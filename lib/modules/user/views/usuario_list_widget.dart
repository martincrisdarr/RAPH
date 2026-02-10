import 'package:flutter/material.dart';

import 'package:raph/shared/models/usuario.dart';

class UsuarioListWidget extends StatelessWidget {
  final List<Usuario> usuarios;
  final Function(Usuario)? onUsuarioTap;

  const UsuarioListWidget({
    super.key,
    required this.usuarios,
    this.onUsuarioTap,
  });

  @override
  Widget build(BuildContext context) {
    if (usuarios.isEmpty) {
      return const Center(
        child: Text('No hay usuarios disponibles.'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: usuarios.length,
      itemBuilder: (context, index) {
        final usuario = usuarios[index];
        final bool esActivo = usuario.activo == 1;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: esActivo ? Colors.green : Colors.grey,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          title: Text('${usuario.nombre}asd ${usuario.apellido}'),
          subtitle: Text(usuario.mail),
          trailing: _buildEstadoChip(usuario.activo),
          onTap: () => onUsuarioTap?.call(usuario),
        );
      },
    );
  }

  Widget _buildEstadoChip(int activo) {
    String texto = 'INACTIVO';
    Color color = Colors.red;

    if (activo == 1) {
      texto = 'ACTIVO';
      color = Colors.green;
    }

    return Chip(
      label: Text(
        texto,
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
      backgroundColor: color,
    );
  }
}

