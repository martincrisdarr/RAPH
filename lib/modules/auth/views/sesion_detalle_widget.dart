import 'package:flutter/material.dart';

import 'package:raph/modules/auth/models/sesion.dart';
import 'package:raph/shared/models/usuario.dart';

class SesionDetalleWidget extends StatelessWidget {
  const SesionDetalleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final sesion = Sesion.sesionActual;

    if (sesion == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_person_outlined,
                size: 64, color: Colors.indigoAccent),
            SizedBox(height: 16),
            Text(
              'No hay ninguna sesión activa en el proyecto.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    final usuario = sesion.usuario;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroHeader(usuario),
          const SizedBox(height: 24),
          _buildSectionTitle('Información de Perfil (Modelo en Librería)'),
          _buildInfoCard([
            _buildDetailRow('Nombre Usuario', usuario.user, Icons.account_circle),
            _buildDetailRow('Email', usuario.mail, Icons.email),
            _buildDetailRow('DNI', usuario.dni.toString(), Icons.badge),
            _buildDetailRow(
              'ID Organismo',
              usuario.idOrganismo.toString(),
              Icons.account_balance,
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionTitle('Tokens y Seguridad'),
          _buildTokenCard(sesion.token),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(Usuario usuario) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.indigo, Colors.blueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, size: 45, color: Colors.white),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${usuario.nombre} ${usuario.apellido}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  usuario.mail,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'SESIÓN ACTIVA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.indigoAccent),
      title: Text(
        label,
        style: const TextStyle(fontSize: 13, color: Colors.grey),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      dense: true,
    );
  }

  Widget _buildTokenCard(String token) {
    return Card(
      color: Colors.black.withOpacity(0.05),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.key, size: 16, color: Colors.orangeAccent),
                SizedBox(width: 8),
                Text('Auth Token', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              token,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.blueGrey,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

