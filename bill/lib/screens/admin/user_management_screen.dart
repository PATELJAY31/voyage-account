import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user_model.dart';
import '../../../widgets/custom_button.dart';

class UserManagementScreen extends StatefulWidget {
  final String? role;
  
  const UserManagementScreen({super.key, this.role});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _searchController = TextEditingController();
  String _selectedRole = 'all';
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.role != null) {
      _selectedRole = widget.role!;
    }
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final users = await authProvider.getAllUsers();
      
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<UserModel> _getFilteredUsers() {
    return _users.where((user) {
      // Role filter
      if (_selectedRole != 'all' && user.roleEnum.name != _selectedRole) {
        return false;
      }
      
      // Search filter
      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        if (!user.name.toLowerCase().contains(searchTerm) &&
            !user.email.toLowerCase().contains(searchTerm)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  void _applyFilters() {
    setState(() {});
  }

  void _clearFilters() {
    setState(() {
      _selectedRole = 'all';
      _searchController.clear();
    });
  }

  Future<void> _createUser() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    AppRole selectedRole = AppRole.employee;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create New User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<AppRole>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: AppRole.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedRole = value ?? AppRole.employee;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        final authProvider = context.read<AuthProvider>();
        await authProvider.createUser(
          nameController.text.trim(),
          emailController.text.trim(),
          passwordController.text,
          selectedRole,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User created successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadUsers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating user: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.updateUserStatus(user.id, !user.isActive);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ${user.isActive ? 'deactivated' : 'activated'} successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating user: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _changeUserRole(UserModel user) async {
    AppRole selectedRole = user.roleEnum;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change User Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Change role for ${user.name}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<AppRole>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'New Role',
                  border: OutlineInputBorder(),
                ),
                items: AppRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedRole = value ?? user.roleEnum;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        final authProvider = context.read<AuthProvider>();
        await authProvider.updateUserRole(user.id, selectedRole);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User role updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadUsers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating user role: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users by name or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (_) => _applyFilters(),
            ),
          ),
          
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[50],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: _selectedRole == 'all',
                    onSelected: () {
                      setState(() {
                        _selectedRole = 'all';
                      });
                      _applyFilters();
                    },
                  ),
                  _FilterChip(
                    label: 'Admin',
                    isSelected: _selectedRole == 'admin',
                    onSelected: () {
                      setState(() {
                        _selectedRole = 'admin';
                      });
                      _applyFilters();
                    },
                  ),
                  _FilterChip(
                    label: 'Engineer',
                    isSelected: _selectedRole == 'engineer',
                    onSelected: () {
                      setState(() {
                        _selectedRole = 'engineer';
                      });
                      _applyFilters();
                    },
                  ),
                  _FilterChip(
                    label: 'Employee',
                    isSelected: _selectedRole == 'employee',
                    onSelected: () {
                      setState(() {
                        _selectedRole = 'employee';
                      });
                      _applyFilters();
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Users List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildUsersList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createUser,
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildUsersList() {
    final filteredUsers = _getFilteredUsers();
    
    if (filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No users found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adjust your filters or create a new user',
              style: TextStyle(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredUsers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return _UserCard(
          user: user,
          onToggleStatus: () => _toggleUserStatus(user),
          onChangeRole: () => _changeUserRole(user),
        );
      },
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Users'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Role',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'engineer', child: Text('Engineer')),
                  DropdownMenuItem(value: 'employee', child: Text('Employee')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    _selectedRole = value ?? 'all';
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _clearFilters();
              },
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _applyFilters();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        backgroundColor: Colors.white,
        selectedColor: const Color(AppColors.primaryColor).withOpacity(0.2),
        checkmarkColor: const Color(AppColors.primaryColor),
        labelStyle: TextStyle(
          color: isSelected 
            ? const Color(AppColors.primaryColor)
            : Colors.grey[600],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onToggleStatus;
  final VoidCallback onChangeRole;

  const _UserCard({
    required this.user,
    required this.onToggleStatus,
    required this.onChangeRole,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getRoleColor(user.roleEnum),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRoleColor(user.roleEnum).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getRoleColor(user.roleEnum),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        user.roleEnum.displayName,
                        style: TextStyle(
                          color: _getRoleColor(user.roleEnum),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: user.isActive 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: user.isActive ? Colors.green : Colors.red,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        user.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: user.isActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onChangeRole,
                    icon: const Icon(Icons.admin_panel_settings, size: 16),
                    label: const Text('Change Role'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(AppColors.primaryColor),
                      side: const BorderSide(color: Color(AppColors.primaryColor)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onToggleStatus,
                    icon: Icon(
                      user.isActive ? Icons.block : Icons.check_circle,
                      size: 16,
                    ),
                    label: Text(user.isActive ? 'Deactivate' : 'Activate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: user.isActive ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(AppRole role) {
    switch (role) {
      case AppRole.admin:
        return Colors.red;
      case AppRole.engineer:
        return Colors.blue;
      case AppRole.employee:
        return Colors.green;
    }
  }
}