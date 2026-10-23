import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  final ImagePicker _picker = ImagePicker();

  String _initialFirstName = '';
  String _initialLastName = '';
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _initialFirstName = user?.firstName ?? '';
    _initialLastName = user?.lastName ?? '';
    if (user != null) {
      _initialized = true;
    }
    _firstNameController = TextEditingController(text: _initialFirstName);
    _lastNameController = TextEditingController(text: _initialLastName);
    _emailController = TextEditingController(text: user?.email ?? '');

    _firstNameController.addListener(_onFieldChanged);
    _lastNameController.addListener(_onFieldChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.watch<AuthProvider>().currentUser;
    if (user != null && !_initialized) {
      _initialFirstName = user.firstName;
      _initialLastName = user.lastName;
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _emailController.text = user.email;
      _initialized = true;
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    final user = context.read<AuthProvider>().currentUser;
    if (_initialFirstName.isEmpty && _initialLastName.isEmpty && user != null) {
      _initialFirstName = user.firstName;
      _initialLastName = user.lastName;
    }
    _firstNameController.removeListener(_onFieldChanged);
    _lastNameController.removeListener(_onFieldChanged);
    _firstNameController.addListener(_onFieldChanged);
    _lastNameController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _firstNameController.removeListener(_onFieldChanged);
    _lastNameController.removeListener(_onFieldChanged);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool _hasChanges(AuthProvider authProvider) {
    final user = authProvider.currentUser;
    final baseFirst = (_initialFirstName.isNotEmpty ? _initialFirstName : (user?.firstName ?? '')).trim();
    final baseLast = (_initialLastName.isNotEmpty ? _initialLastName : (user?.lastName ?? '')).trim();
    final inputFirst = _firstNameController.text.trim();
    final inputLast = _lastNameController.text.trim();

    final isModified = inputFirst != baseFirst || inputLast != baseLast;
    final isValid = inputFirst.isNotEmpty && inputLast.isNotEmpty;

    return isModified && isValid;
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // Cierra bottom sheet
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      final filename = image.name.isNotEmpty ? image.name : 'avatar.jpg';

      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.uploadAvatarBytes(
        bytes: bytes,
        filename: filename,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Foto de perfil actualizada' : (authProvider.errorMessage ?? 'Error al subir imagen')),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              children: [
                const ListTile(
                  title: Text('Seleccionar Foto de Perfil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera, color: AppColors.primary),
                  title: const Text('Tomar Foto con Cámara'),
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppColors.primary),
                  title: const Text('Elegir de la Galería'),
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final newFirst = _firstNameController.text.trim();
    final newLast = _lastNameController.text.trim();

    final success = await authProvider.updateProfile(
      firstName: newFirst,
      lastName: newLast,
    );

    if (mounted) {
      if (success) {
        setState(() {
          _initialFirstName = newFirst;
          _initialLastName = newLast;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Perfil actualizado con éxito' : (authProvider.errorMessage ?? 'Error al actualizar')),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: AbsorbPointer(
                  absorbing: authProvider.isActionLoading,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Avatar Interactivo
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 54,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                              backgroundImage: user?.profileImageUrl != null
                                  ? NetworkImage(user!.profileImageUrl!)
                                  : null,
                              child: user?.profileImageUrl == null
                                  ? Text(
                                      user != null && user.firstName.isNotEmpty
                                          ? user.firstName[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    )
                                  : null,
                            ),
                            InkWell(
                              onTap: authProvider.isActionLoading ? null : _showImagePickerModal,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Badge de Rol
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: user?.isAdmin == true ? Colors.deepPurple.shade50 : Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: user?.isAdmin == true ? Colors.deepPurple : Colors.teal,
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            (user?.role ?? 'trainer').toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: user?.isAdmin == true ? Colors.deepPurple : Colors.teal,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // CAMPO EMAIL: READ-ONLY CON CANDADO
                        TextFormField(
                          controller: _emailController,
                          enabled: false,
                          decoration: InputDecoration(
                            labelText: 'Correo Electrónico',
                            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                            helperText: 'El correo electrónico no puede ser modificado.',
                            helperStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _firstNameController,
                          onChanged: (_) {
                            if (mounted) setState(() {});
                          },
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          ),
                          validator: (value) => (value == null || value.trim().isEmpty) ? 'Ingresa tu nombre' : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _lastNameController,
                          onChanged: (_) {
                            if (mounted) setState(() {});
                          },
                          decoration: const InputDecoration(
                            labelText: 'Apellido',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          ),
                          validator: (value) => (value == null || value.trim().isEmpty) ? 'Ingresa tu apellido' : null,
                        ),
                        const SizedBox(height: 28),

                        ListenableBuilder(
                          listenable: Listenable.merge([_firstNameController, _lastNameController]),
                          builder: (context, _) {
                            final canSave = !authProvider.isActionLoading && _hasChanges(authProvider);
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: canSave ? _saveChanges : null,
                                icon: authProvider.isActionLoading
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.save_outlined),
                                label: const Text('Guardar Cambios', style: TextStyle(fontSize: 16)),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: authProvider.isActionLoading ? null : () => authProvider.logout(),
                            icon: const Icon(Icons.logout, color: AppColors.error),
                            label: const Text('Cerrar Sesión', style: TextStyle(color: AppColors.error)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: AppColors.error),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}