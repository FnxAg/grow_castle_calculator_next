import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grow_castle_calculator_next/core/calc/quick_calc.dart';
import 'package:grow_castle_calculator_next/core/extension/num.dart';
import 'package:grow_castle_calculator_next/l10n/app_localizations.dart';
import 'package:grow_castle_calculator_next/provider/userdata/user_data_selectors.dart';
import 'package:grow_castle_calculator_next/view/extension/context_l10n.dart';
import 'package:grow_castle_calculator_next/view/widget/select_all_text_field.dart';
import 'package:material_ui/material_ui.dart';

enum _Field { wave, gp, gpCN, gold }

class QuickCalculationPage extends ConsumerStatefulWidget {
  const QuickCalculationPage({super.key});

  @override
  ConsumerState<QuickCalculationPage> createState() =>
      _QuickCalculationPageState();
}

class _QuickCalculationPageState extends ConsumerState<QuickCalculationPage> {
  static String _wave = '';
  static String _gp = '';
  static String _gpCN = '';
  static String _gold = '';
  static _Field? _lockedField;

  final TextEditingController _waveController = TextEditingController();
  final TextEditingController _gpController = TextEditingController();
  final TextEditingController _gpCNController = TextEditingController();
  final TextEditingController _goldController = TextEditingController();

  /// 正在写入计算结果，忽略由此触发的输入监听
  bool _applying = false;
  _Field? _lastEdited;

  @override
  void initState() {
    super.initState();
    _waveController
      ..text = _wave
      ..addListener(_onWaveChanged);
    _gpController
      ..text = _gp
      ..addListener(_onGpChanged);
    _gpCNController
      ..text = _gpCN
      ..addListener(_onGpCNChanged);
    _goldController
      ..text = _gold
      ..addListener(_onGoldChanged);
  }

  @override
  void dispose() {
    _wave = _waveController.text;
    _gp = _gpController.text;
    _gpCN = _gpCNController.text;
    _gold = _goldController.text;
    _waveController
      ..removeListener(_onWaveChanged)
      ..dispose();
    _gpController
      ..removeListener(_onGpChanged)
      ..dispose();
    _gpCNController
      ..removeListener(_onGpCNChanged)
      ..dispose();
    _goldController
      ..removeListener(_onGoldChanged)
      ..dispose();
    super.dispose();
  }

  void _onWaveChanged() => _onChanged(_Field.wave);

  void _onGpChanged() => _onChanged(_Field.gp);

  void _onGpCNChanged() => _onChanged(_Field.gpCN);

  void _onGoldChanged() => _onChanged(_Field.gold);

  void _onChanged(_Field field) {
    if (_applying) return;
    _lastEdited = field;
    _wave = _waveController.text;
    _gp = _gpController.text;
    _gpCN = _gpCNController.text;
    _gold = _goldController.text;
    setState(() {});
    if (_lockedField != null && _lockedField != field) _recalculate(field);
  }

  /// 把当前用户对应项的数据填入输入框
  void _fillFromCurrentUser(_Field field) {
    final text = switch (field) {
      _Field.wave => ref.read(currentUserWaveProvider).toString(),
      _Field.gp => _formatDecimal(ref.read(currentUserGpProvider)),
      _Field.gpCN => _formatDecimal(ref.read(currentUserGpCnProvider)),
      _Field.gold => ref.read(currentUserTotalGoldProvider).round().toString(),
    };
    final l10n = AppLocalizations.of(context);
    _setField(field, text);
    _lastEdited = field;
    if (_lockedField != null) {
      if (_lockedField == field) {
        _recalculateAfterLock();
      } else {
        _recalculate(field);
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_labelOf(l10n, field)} -> $text'),
        duration: const Duration(seconds: 1),
      ),
    );
    setState(() {});
  }

  void _toggleLock(_Field field) {
    if (_lockedField == field) {
      setState(() => _lockedField = null);
      return;
    }
    if ((_valueOf(field) ?? 0) <= 0) return;
    final isEmpty =
        _valueOf(_Field.wave) == null && _valueOf(_Field.gold) == null;
    setState(() {
      if (field == _Field.gp && isEmpty) {
        _setField(_Field.gpCN, '');
      }
      if (field == _Field.gpCN && isEmpty) {
        _setField(_Field.gp, '');
      }
      _lockedField = field;
    });
    _recalculateAfterLock();
  }

  /// 刚锁定时，用已有的另一项数值立即补算
  /// 
  /// **注意**：当_lastEdited为两项指数时，可能会出现越界，
  /// 导致总波数与总金币的输入框被清空
  void _recalculateAfterLock() {
    final lock = _lockedField;
    if (lock == null) return;
    final last = _lastEdited;
    if (last != null && last != lock && (_valueOf(last) ?? 0) > 0) {
      _recalculate(last);
      return;
    }
    for (final field in _Field.values) {
      if (field == lock) continue;
      if ((_valueOf(field) ?? 0) > 0) {
        _recalculate(field);
        return;
      }
    }
  }

  /// 以锁定项与本次编辑项为已知量，补算另外两项
  void _recalculate(_Field source) {
    final lock = _lockedField;
    if (lock == null || lock == source) return;
    final w = _valueOf(_Field.wave);
    final g = _valueOf(_Field.gold);
    final p = _valueOf(_Field.gp);
    final c = _valueOf(_Field.gpCN);

    void setWave(double? value) => _setField(
      _Field.wave,
      value == null || !value.isFinite ? '' : value.round().toString(),
    );
    void setGold(double? value) => _setField(
      _Field.gold,
      value == null || !value.isFinite ? '' : value.round().toString(),
    );
    void setGp(double? value) => _setField(
      _Field.gp,
      value == null || !value.isFinite ? '' : _formatDecimal(value),
    );
    void setGpCN(double? value) => _setField(
      _Field.gpCN,
      value == null || !value.isFinite ? '' : _formatDecimal(value),
    );

    final known = {lock, source};
    void clearOutputs() {
      for (final field in _Field.values) {
        if (!known.contains(field)) _setField(field, '');
      }
    }

    final hasWave = known.contains(_Field.wave);
    final hasGold = known.contains(_Field.gold);
    final hasGp = known.contains(_Field.gp);
    final hasGpCN = known.contains(_Field.gpCN);

    if (hasWave && hasGold) {
      if (w == null || w <= 0 || g == null || g <= 0) {
        clearOutputs();
        return;
      }
      setGp(gpFromWaveGold(w, g));
      setGpCN(gpCNFromWaveGold(w, g));
    } else if (hasWave && hasGp) {
      if (w == null || w <= 0 || p == null || p <= 0) {
        clearOutputs();
        return;
      }
      final gold = goldFromWaveGp(w, p);
      setGold(gold);
      setGpCN(gpCNFromWaveGold(w, gold));
    } else if (hasWave && hasGpCN) {
      if (w == null || w <= 0 || c == null || c <= 0) {
        clearOutputs();
        return;
      }
      final gold = goldFromWaveGpCN(w, c);
      setGold(gold);
      setGp(gpFromWaveGold(w, gold));
    } else if (hasGold && hasGp) {
      if (g == null || g <= 0 || p == null || p <= 0) {
        clearOutputs();
        return;
      }
      final wave = waveFromGoldGp(g, p);
      if (wave == null) {
        clearOutputs();
        return;
      }
      setWave(wave);
      setGpCN(gpCNFromWaveGold(wave, g));
    } else if (hasGold && hasGpCN) {
      if (g == null || g <= 0 || c == null || c <= 0) {
        clearOutputs();
        return;
      }
      final wave = waveFromGoldGpCN(g, c);
      if (wave == null) {
        clearOutputs();
        return;
      }
      setWave(wave);
      setGp(gpFromWaveGold(wave, g));
    } else if (hasGp && hasGpCN) {
      if (p == null || p <= 0 || c == null || c <= 0) {
        clearOutputs();
        return;
      }
      final wave = waveFromGpGpCN(p, c);
      if (wave == null) {
        clearOutputs();
        return;
      }
      setWave(wave);
      setGold(goldFromWaveGpCN(wave, c));
    }
  }

  void _setField(_Field field, String text) {
    final controller = _controllerOf(field);
    if (controller.text == text) return;
    _applying = true;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _applying = false;
    switch (field) {
      case _Field.wave:
        _wave = text;
      case _Field.gp:
        _gp = text;
      case _Field.gpCN:
        _gpCN = text;
      case _Field.gold:
        _gold = text;
    }
  }

  double? _valueOf(_Field field) {
    final text = _controllerOf(field).text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  TextEditingController _controllerOf(_Field field) => switch (field) {
    _Field.wave => _waveController,
    _Field.gp => _gpController,
    _Field.gpCN => _gpCNController,
    _Field.gold => _goldController,
  };

  static String _formatDecimal(double value) {
    if (!value.isFinite) return '';
    var text = value.toStringAsFixed(3);
    if (text.contains('.')) {
      text = text.replaceFirst(RegExp(r'0+$'), '');
      text = text.replaceFirst(RegExp(r'\.$'), '');
    }
    return text;
  }

  String _labelOf(AppLocalizations l10n, _Field field) => switch (field) {
    _Field.wave => l10n.totalWave,
    _Field.gp => l10n.gp,
    _Field.gpCN => l10n.gpCN,
    _Field.gold => l10n.totalGold,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.toolQuickCalculation),
        actions: _buildAppBarActions(l10n),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            l10n.quickCalcHint,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16.0),
          for (final field in _Field.values) ...[
            Row(
              children: [
                Expanded(child: _buildField(l10n, field)),
                _buildLockButton(l10n, field),
                _buildFillButton(l10n, field),
              ],
            ),
            if (field != _Field.values.last) const SizedBox(height: 12.0),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildAppBarActions(AppLocalizations l10n) {
    return [
      IconButton(
        tooltip: l10n.actionResetToDefault,
        icon: const Icon(Icons.refresh),
        onPressed: () {
          setState(() {
            _wave = '';
            _gp = '';
            _gpCN = '';
            _gold = '';
            _lockedField = null;
            _waveController.text = '';
            _gpController.text = '';
            _gpCNController.text = '';
            _goldController.text = '';
          });
        },
      ),
    ];
  }

  Widget _buildField(AppLocalizations l10n, _Field field) {
    final english = !context.isChineseLocale;
    final traditional = context.isTraditionalChineseLocale;
    return SelectAllTextField(
      controller: _controllerOf(field),
      enabled: _isFieldEnabled(field),
      keyboardType: field == _Field.wave
          ? TextInputType.number
          : const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      maxLines: 1,
      inputFormatters: field == _Field.wave
          ? [FilteringTextInputFormatter.digitsOnly]
          : const [_DecimalTextInputFormatter()],
      decoration: InputDecoration(
        labelText: _labelOf(l10n, field),
        helperText: _valueOf(field) == null
            ? '-'
            : switch (field) {
                _Field.wave => _valueOf(field)?.format(fractionDigits: 0),
                _Field.gold => _valueOf(
                  field,
                )?.formatCompact(english: english, traditional: traditional),
                _ => _valueOf(field)?.format(fractionDigits: 3),
              },
      ),
    );
  }

  Widget _buildFillButton(AppLocalizations l10n, _Field field) {
    return IconButton(
      tooltip: l10n.quickCalcFill,
      visualDensity: VisualDensity.compact,
      iconSize: 20.0,
      icon: const Icon(Icons.edit),
      onPressed: _isFieldEnabled(field)
          ? () => _fillFromCurrentUser(field)
          : null,
    );
  }

  bool _isFieldEnabled(_Field field) {
    if (field == _lockedField) return false;
    return switch (field) {
      _Field.gp => _lockedField != _Field.gpCN,
      _Field.gpCN => _lockedField != _Field.gp,
      _ => true,
    };
  }

  Widget _buildLockButton(AppLocalizations l10n, _Field field) {
    final locked = _lockedField == field;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: IconButton(
        tooltip: locked ? l10n.quickCalcUnlock : l10n.quickCalcLock,
        visualDensity: VisualDensity.compact,
        iconSize: 20.0,
        icon: Icon(
          locked ? Icons.lock : Icons.lock_open,
          color: locked ? scheme.primary : scheme.onSurfaceVariant,
        ),
        onPressed: locked || (_valueOf(field) ?? 0) > 0
            ? () => _toggleLock(field)
            : null,
      ),
    );
  }
}

/// 小数输入：只允许一个点
class _DecimalTextInputFormatter extends TextInputFormatter {
  const _DecimalTextInputFormatter();

  static final RegExp _pattern = RegExp(r'^\d*\.?\d*$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _pattern.hasMatch(newValue.text) ? newValue : oldValue;
  }
}
