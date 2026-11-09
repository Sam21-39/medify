import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/di/injection_container.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../domain/entities/user_profile.dart';
import '../blocs/profile/profile_cubit.dart';
import '../blocs/profile/profile_state.dart';

/// Page for adding or editing a user profile
class AddEditProfilePage extends StatefulWidget {
  final UserProfile? profile;

  const AddEditProfilePage({super.key, this.profile});

  @override
  State<AddEditProfilePage> createState() => _AddEditProfilePageState();
}

class _AddEditProfilePageState extends State<AddEditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedRelationship;
  String _selectedAvatar = ProfileAvatars.defaultAvatar;
  int _selectedColor = ProfileColors.defaultColor;
  DateTime? _selectedDateOfBirth;

  bool get _isEditing => widget.profile != null;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    if (widget.profile != null) {
      _nameController.text = widget.profile!.name;
      _notesController.text = widget.profile!.notes ?? '';
      _selectedRelationship = widget.profile!.relationship;
      _selectedAvatar =
          widget.profile!.avatarEmoji ?? ProfileAvatars.defaultAvatar;
      _selectedColor = widget.profile!.colorValue;
      _selectedDateOfBirth = widget.profile!.dateOfBirth;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileCubit>(),
      child: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context);
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is ProfileLoading;

          return Scaffold(
            appBar: AppBar(
              title: Text(_isEditing ? 'Edit Profile' : 'Add Profile'),
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.paddingL),
                children: [
                  // Avatar selection
                  _buildAvatarSelection(),
                  const SizedBox(height: AppSizes.paddingXL),

                  // Color selection
                  _buildColorSelection(),
                  const SizedBox(height: AppSizes.paddingXL),

                  // Name field
                  CustomTextField(
                    label: 'Name',
                    hint: 'e.g., John, Mom, Grandpa',
                    controller: _nameController,
                    prefixIcon: const Icon(Icons.person),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      if (value.length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.paddingL),

                  // Relationship dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedRelationship,
                    decoration: const InputDecoration(
                      labelText: 'Relationship',
                      prefixIcon: Icon(Icons.family_restroom),
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Select relationship'),
                    items: ProfileRelationships.all.map((relationship) {
                      return DropdownMenuItem(
                        value: relationship,
                        child: Text(relationship),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRelationship = value;
                      });
                    },
                  ),
                  const SizedBox(height: AppSizes.paddingL),

                  // Date of birth
                  _buildDateOfBirthField(),
                  const SizedBox(height: AppSizes.paddingL),

                  // Notes
                  CustomTextField(
                    label: 'Notes (Optional)',
                    hint: 'Any additional information',
                    controller: _notesController,
                    prefixIcon: const Icon(Icons.note),
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSizes.paddingXL),

                  // Save button
                  FilledButton(
                    onPressed: isLoading ? null : _saveProfile,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSizes.paddingM,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _isEditing ? 'Update Profile' : 'Create Profile',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatarSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Avatar', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSizes.paddingM),
        Container(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: ProfileAvatars.all.length,
            itemBuilder: (context, index) {
              final avatar = ProfileAvatars.all[index];
              final isSelected = avatar == _selectedAvatar;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAvatar = avatar;
                  });
                },
                child: Container(
                  width: 70,
                  height: 70,
                  margin: const EdgeInsets.only(right: AppSizes.paddingM),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Color(_selectedColor).withValues(alpha: 0.2)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Color(_selectedColor)
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(avatar, style: const TextStyle(fontSize: 36)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Color Theme', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSizes.paddingM),
        Wrap(
          spacing: AppSizes.paddingM,
          runSpacing: AppSizes.paddingM,
          children: ProfileColors.all.map((color) {
            final isSelected = color == _selectedColor;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                });
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Color(color),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Color(color).withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 28)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateOfBirthField() {
    return InkWell(
      onTap: _selectDateOfBirth,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date of Birth (Optional)',
          prefixIcon: Icon(Icons.cake),
          border: OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedDateOfBirth != null
                  ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                  : 'Select date',
              style: TextStyle(
                color: _selectedDateOfBirth != null
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            if (_selectedDateOfBirth != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  setState(() {
                    _selectedDateOfBirth = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateOfBirth() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate:
          _selectedDateOfBirth ??
          DateTime.now().subtract(const Duration(days: 365 * 30)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDateOfBirth = pickedDate;
      });
    }
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final now = DateTime.now();
    final profile = UserProfile(
      id: widget.profile?.id,
      name: _nameController.text.trim(),
      avatarEmoji: _selectedAvatar,
      colorValue: _selectedColor,
      relationship: _selectedRelationship,
      dateOfBirth: _selectedDateOfBirth,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      isActive: widget.profile?.isActive ?? true,
      isDefaultProfile: widget.profile?.isDefaultProfile ?? false,
      createdAt: widget.profile?.createdAt ?? now,
      updatedAt: now,
    );

    if (_isEditing) {
      getIt<ProfileCubit>().updateProfile(profile);
    } else {
      getIt<ProfileCubit>().createProfile(profile);
    }
  }
}
