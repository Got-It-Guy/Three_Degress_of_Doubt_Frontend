import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:three_degress_of_doubt_frontend/core/di/app_dependencies.dart';

class MetadataSetupScreen extends StatefulWidget {
  const MetadataSetupScreen({super.key});

  @override
  State<MetadataSetupScreen> createState() => _MetadataSetupScreenState();
}

class _MetadataSetupScreenState extends State<MetadataSetupScreen> {
  final _authRepository = AppDependencies.authRepository;

  bool _isInitialLoading = true;
  bool _isSaving = false;

  String? _selectedAge;
  String? _selectedJob;
  String? _selectedBank;
  String? _selectedResidence;

  final List<String> _ageGroups =
      List.generate(10, (i) => "${(i + 1) * 10}대");

  final List<String> _jobs = [
    "대학생",
    "직장인",
    "전문직",
    "자영업자",
    "공무원",
    "주부",
    "무직",
    "기타"
  ];

  final List<String> _banks = [
    "국민은행",
    "신한은행",
    "우리은행",
    "하나은행",
    "농협은행",
    "기업은행",
    "카카오뱅크",
    "토스뱅크",
    "케이뱅크"
  ];

  final List<String> _residences = [
    "서울특별시",
    "부산광역시",
    "대구광역시",
    "인천광역시",
    "광주광역시",
    "대전광역시",
    "울산광역시",
    "세종특별자치시",
    "경기도",
    "강원도",
    "충청북도",
    "충청남도",
    "전북특별자치도",
    "전남특별자치도",
    "경상북도",
    "경상남도",
    "제주특별자치도"
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentMetadata();
  }

  Future<void> _loadCurrentMetadata() async {
    setState(() => _isInitialLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return;

      final idToken = await user.getIdToken();

      if (idToken == null) return;

      final profile =
          await _authRepository.fetchMyProfile(idToken: idToken);

      if (!mounted) return;

      setState(() {
        _selectedAge = profile.ageGroup;
        _selectedJob = profile.job;
        _selectedBank = profile.mainBank;
        _selectedResidence = profile.residence;
        _isInitialLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isInitialLoading = false);
        debugPrint("기존 메타데이터 로딩 실패: $e");
      }
    }
  }

  Future<void> _saveMetadata() async {
    if (_selectedAge == null ||
        _selectedJob == null ||
        _selectedBank == null ||
        _selectedResidence == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 선택해 주세요.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken() ?? "";

      await _authRepository.updateUserMetadata(
        idToken: idToken,
        metadata: {
          "name": user?.displayName ?? "사용자",
          "ageGroup": _selectedAge,
          "job": _selectedJob,
          "mainBank": _selectedBank,
          "residence": _selectedResidence,
        },
      );

      if (!mounted) return;

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 중 오류 발생: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF020911);
    const primaryGreen = Color(0xFF00D64F);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text(
          '프로필 설정',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isInitialLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: primaryGreen,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "맞춤형 사기 예방을 위해\n정보를 선택해 주세요.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildSelectableTile(
                    "연령대",
                    _selectedAge,
                    _ageGroups,
                    (val) => setState(() => _selectedAge = val),
                  ),
                  _buildSelectableTile(
                    "직업",
                    _selectedJob,
                    _jobs,
                    (val) => setState(() => _selectedJob = val),
                  ),
                  _buildSelectableTile(
                    "주거래 은행",
                    _selectedBank,
                    _banks,
                    (val) => setState(() => _selectedBank = val),
                  ),
                  _buildSelectableTile(
                    "거주 지역",
                    _selectedResidence,
                    _residences,
                    (val) => setState(() => _selectedResidence = val),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveMetadata,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: bgColor,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "설정 완료",
                              style: TextStyle(
                                color: bgColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSelectableTile(
    String title,
    String? selectedValue,
    List<String> items,
    Function(String) onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showListPicker(title, items, onSelect),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF111A24),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedValue != null
                    ? const Color(0xFF00D64F)
                    : const Color(0xFF223042),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedValue ?? "$title 선택",
                  style: TextStyle(
                    color: selectedValue != null
                        ? Colors.white
                        : Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showListPicker(
    String title,
    List<String> items,
    Function(String) onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111A24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (_, controller) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: controller,
                    itemCount: items.length,
                    separatorBuilder: (context, index) => Divider(
                      color: Colors.grey[900],
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                          items[index],
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        onTap: () {
                          onSelect(items[index]);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}