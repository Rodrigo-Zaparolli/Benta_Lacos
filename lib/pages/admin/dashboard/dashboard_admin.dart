import 'package:flutter/material.dart';
import '../login/admin_page.dart';

/// Compatibility route; all administrative screens now share the guarded shell.
class DashboardAdminPage extends StatelessWidget {
  const DashboardAdminPage({super.key});
  @override
  Widget build(BuildContext context) => const AdminPage();
}
