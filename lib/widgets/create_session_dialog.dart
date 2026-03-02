import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

/// Dialog for creating a new Ramadhan session
/// Requirements: 1.1, 1.3, 1.4
class CreateSessionDialog extends StatefulWidget {
  const CreateSessionDialog({super.key});

  @override
  State<CreateSessionDialog> createState() => _CreateSessionDialogState();
}

class _CreateSessionDialogState extends State<CreateSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _yearController = TextEditingController();
  final _currentDayController = TextEditingController();
  
  DateTime _startDate = DateTime.now();
  int _duration = 30; // Default to 30 days
  bool _isMidRamadhan = false;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    // Set default year to current year
    _yearController.text = DateTime.now().year.toString();
    _currentDayController.text = '1';
  }

  @override
  void dispose() {
    _yearController.dispose();
    _currentDayController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF10B981), // Emerald
              onPrimary: Colors.white,
              surface: Color(0xFF1F2937),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _createSession() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final year = int.parse(_yearController.text);
      final currentDay = _isMidRamadhan 
          ? int.parse(_currentDayController.text) 
          : null;

      final appState = Provider.of<AppState>(context, listen: false);
      final t = appState.localizationService.translate;
      
      await appState.createNewSession(
        year: year,
        startDate: _startDate,
        totalDays: _duration,
        currentDayNumber: currentDay,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('create_session.success')),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        final t = appState.localizationService.translate;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t('create_session.error')} $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final t = appState.localizationService.translate;
    
    return Dialog(
      backgroundColor: const Color(0xFF1F2937),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Row(
                  children: [
                    const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF10B981),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      t('create_session.title'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Year input
                TextFormField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: t('create_session.year'),
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: t('create_session.year_hint'),
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(
                      Icons.calendar_today,
                      color: Color(0xFF10B981),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF374151)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF374151)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF10B981)),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF111827),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return t('create_session.year_required');
                    }
                    final year = int.tryParse(value);
                    if (year == null) {
                      return t('create_session.year_invalid');
                    }
                    if (year < 2020 || year > 2100) {
                      return t('create_session.year_range');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Start date picker
                InkWell(
                  onTap: () => _selectStartDate(context),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF374151)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.event,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t('create_session.start_date'),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Duration selector
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF374151)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.timelapse,
                            color: Color(0xFF10B981),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            t('create_session.duration'),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDurationOption(29, t),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDurationOption(30, t),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Mid-Ramadhan toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF374151)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFFD97706),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t('create_session.mid_ramadhan'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Switch(
                            value: _isMidRamadhan,
                            onChanged: (value) {
                              setState(() {
                                _isMidRamadhan = value;
                              });
                            },
                            activeColor: const Color(0xFF10B981),
                          ),
                        ],
                      ),
                      if (_isMidRamadhan) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _currentDayController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: t('create_session.current_day_number'),
                            labelStyle: const TextStyle(color: Colors.white70),
                            hintText: t('create_session.current_day_hint'),
                            hintStyle: const TextStyle(color: Colors.white38),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF374151),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF374151),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF10B981),
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF1F2937),
                          ),
                          validator: (value) {
                            if (_isMidRamadhan) {
                              if (value == null || value.isEmpty) {
                                return t('create_session.current_day_required');
                              }
                              final day = int.tryParse(value);
                              if (day == null) {
                                return t('create_session.current_day_invalid');
                              }
                              if (day < 1 || day > _duration) {
                                return '${t('create_session.current_day_range')} $_duration';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isCreating
                            ? null
                            : () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFF374151)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          t('create_session.cancel'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isCreating ? null : _createSession,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isCreating
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                t('create_session.create'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDurationOption(int days, Function(String) t) {
    final isSelected = _duration == days;
    
    return InkWell(
      onTap: () {
        setState(() {
          _duration = days;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : const Color(0xFF374151),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            '${days} ${t('create_session.days')}',
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
