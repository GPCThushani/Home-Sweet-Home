import 'package:flutter/material.dart';
import 'home_features_screen.dart';

class FamilyMember {
  String name;
  String role;
  String gender;
  bool hasAccount;

  FamilyMember({
    required this.name,
    required this.role,
    required this.gender,
    this.hasAccount = false,
  });

  bool get isPlaceholder => name.isEmpty || name.contains("'s Name");

  String get avatarAsset {
    final normalizedRole = role.toLowerCase().trim();
    final normalizedGender = gender.toLowerCase().trim();

    if (normalizedRole.contains('grandfather') || normalizedRole.contains('grandpa')) {
      return 'assets/images/family_members/grandfather.jpg';
    }
    if (normalizedRole.contains('grandmother') || normalizedRole.contains('grandma')) {
      return 'assets/images/family_members/grandmother.jpg';
    }
    if (normalizedRole.contains('father') || normalizedRole.contains('dad')) {
      return 'assets/images/family_members/father.jpg';
    }
    if (normalizedRole.contains('mother') || normalizedRole.contains('mom')) {
      return 'assets/images/family_members/mother.jpg';
    }
    if (normalizedRole.contains('son') || normalizedRole.contains('boy')) {
      return 'assets/images/family_members/son.jpg';
    }
    if (normalizedRole.contains('daughter') || normalizedRole.contains('girl')) {
      return 'assets/images/family_members/daughter.jpg';
    }

    if (normalizedGender == 'female') {
      return 'assets/images/family_members/female.jpg';
    }
    return 'assets/images/family_members/male.jpg';
  }
}

class AddFamilyMembersScreen extends StatefulWidget {
  final String familyName;
  final String familyMotto;
  final String? customAvatarPath;
  final int? presetAvatarIndex;
  final String userEmail;

  const AddFamilyMembersScreen({
    super.key,
    required this.familyName,
    required this.familyMotto,
    this.customAvatarPath,
    this.presetAvatarIndex,
    required this.userEmail,
  });

  @override
  State<AddFamilyMembersScreen> createState() => _AddFamilyMembersScreenState();
}

class _AddFamilyMembersScreenState extends State<AddFamilyMembersScreen> {
  final List<FamilyMember> _members = [
    FamilyMember(name: "Father's Name", role: 'Father', gender: 'Male', hasAccount: true),
    FamilyMember(name: "Mother's Name", role: 'Mother', gender: 'Female', hasAccount: false),
    FamilyMember(name: "Son's Name", role: 'Son', gender: 'Male', hasAccount: false),
    FamilyMember(name: "Daughter's Name", role: 'Daughter', gender: 'Female', hasAccount: false),
  ];

  int _creatorProfileIndex = 0;

  void _showMemberDialog({FamilyMember? memberToEdit, int? index}) {
    final initialName = (memberToEdit == null || memberToEdit.isPlaceholder) ? '' : memberToEdit.name;
    final nameController = TextEditingController(text: initialName);
    final customRoleController = TextEditingController();

    final standardRoles = ['Father', 'Mother', 'Grandfather', 'Grandmother', 'Son', 'Daughter'];
    bool isStandardRole = memberToEdit == null || standardRoles.contains(memberToEdit.role);

    String selectedRole = isStandardRole ? (memberToEdit?.role ?? 'Son') : 'Other';
    if (!isStandardRole) {
      customRoleController.text = memberToEdit.role;
    }

    String selectedGender = memberToEdit?.gender ?? 'Male';
    bool needsAccount = memberToEdit?.hasAccount ?? false;
    final List<String> availableRoles = [...standardRoles, 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memberToEdit == null ? 'Add Family Member' : 'Edit Member Details',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF244032)),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Member Name',
                      hintText: 'Type name here...',
                      filled: true,
                      fillColor: const Color(0xFFF8FAF9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF4A8B71))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Family Role', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF244032))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAF9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButton<String>(
                      value: selectedRole,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: availableRoles.map((role) {
                        return DropdownMenuItem(value: role, child: Text(role));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() {
                            selectedRole = value;
                            if (value != 'Other') {
                              if (value == 'Mother' || value == 'Grandmother' || value == 'Daughter') {
                                selectedGender = 'Female';
                              } else if (value == 'Father' || value == 'Grandfather' || value == 'Son') {
                                selectedGender = 'Male';
                              }
                            }
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (selectedRole == 'Other') ...[
                    TextField(
                      controller: customRoleController,
                      decoration: InputDecoration(
                        labelText: 'Specify Relation (e.g. Uncle, Aunty, Cousin)',
                        filled: true,
                        fillColor: const Color(0xFFF8FAF9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text('Gender', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF244032))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAF9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButton<String>(
                      value: selectedGender,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: ['Male', 'Female'].map((gender) {
                        return DropdownMenuItem(value: gender, child: Text(gender));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => selectedGender = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Allow member to sign in', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF244032))),
                    subtitle: const Text('Generates an invite link for them', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    value: needsAccount,
                    // ignore: deprecated_member_use
                    activeColor: const Color(0xFF4A8B71),
                    onChanged: (val) => setModalState(() => needsAccount = val),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      final enteredName = nameController.text.trim();
                      final finalRole = selectedRole == 'Other'
                          ? (customRoleController.text.trim().isEmpty ? 'Family Member' : customRoleController.text.trim())
                          : selectedRole;
                      final finalName = enteredName.isEmpty ? "$finalRole's Name" : enteredName;

                      setState(() {
                        if (memberToEdit == null) {
                          _members.add(FamilyMember(
                            name: finalName,
                            role: finalRole,
                            gender: selectedGender,
                            hasAccount: needsAccount,
                          ));
                        } else {
                          memberToEdit.name = finalName;
                          memberToEdit.role = finalRole;
                          memberToEdit.gender = selectedGender;
                          memberToEdit.hasAccount = needsAccount;
                        }
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A8B71),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(memberToEdit == null ? 'Add Member' : 'Save Changes', style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _confirmDelete(int index) {
    if (_members.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must keep at least one family member profile.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove ${_members[index].name} from the roster?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _members.removeAt(index);
                if (_creatorProfileIndex >= _members.length) {
                  _creatorProfileIndex = _members.length - 1;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF244032)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Family Members',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF244032)),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select which profile corresponds to YOU (The Creator):',
                style: TextStyle(fontSize: 13, color: Color(0xFF4A8B71), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    final isCreator = _creatorProfileIndex == index;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isCreator ? const Color(0xFFE8F2ED) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCreator ? const Color(0xFF4A8B71) : Colors.grey.shade200,
                          width: isCreator ? 2 : 1.5,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _showMemberDialog(memberToEdit: member, index: index),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Radio<int>(
                                value: index,
                                // ignore: deprecated_member_use
                                groupValue: _creatorProfileIndex,
                                activeColor: const Color(0xFF4A8B71),
                                // ignore: deprecated_member_use
                                onChanged: (val) {
                                  if (val != null) setState(() => _creatorProfileIndex = val);
                                },
                              ),
                              const SizedBox(width: 4),
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(0xFFE8F2ED),
                                child: ClipOval(
                                  child: Image.asset(
                                    member.avatarAsset,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.person, color: Color(0xFF4A8B71), size: 22),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: member.isPlaceholder ? Colors.grey.shade400 : const Color(0xFF244032),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      member.role,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade600),
                                tooltip: 'Edit Member',
                                onPressed: () => _showMemberDialog(memberToEdit: member, index: index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                tooltip: 'Remove Member',
                                onPressed: () => _confirmDelete(index),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showMemberDialog(),
                icon: const Icon(Icons.add_rounded, color: Color(0xFF4A8B71)),
                label: const Text('Add another member', style: TextStyle(color: Color(0xFF4A8B71), fontWeight: FontWeight.bold, fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  side: const BorderSide(color: Color(0xFF4A8B71), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final serializedMembers = _members.map((m) => {
                    'name': m.isPlaceholder ? m.role : m.name,
                    'role': m.role,
                    'gender': m.gender,
                    'invitePreferred': m.hasAccount,
                  }).toList();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeFeaturesScreen(
                        familyName: widget.familyName,
                        familyMotto: widget.familyMotto,
                        customAvatarPath: widget.customAvatarPath,
                        presetAvatarIndex: widget.presetAvatarIndex,
                        memberCount: _members.length,
                        userEmail: widget.userEmail,
                        familyMembers: serializedMembers,
                        creatorProfileIndex: _creatorProfileIndex,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A8B71),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}