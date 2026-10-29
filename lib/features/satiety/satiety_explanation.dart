import 'package:flutter/material.dart';
import 'satiety_estimate.dart';

const satietyStructureLabels = {
  FoodStructure.solid: 'Нужно жевать',
  FoodStructure.soft: 'Мягкая / пюре',
  FoodStructure.liquid: 'Жидкая',
  FoodStructure.mixed: 'Смешанная',
};

class SatietyExplanation extends StatelessWidget {
  const SatietyExplanation({super.key});
  @override
  Widget build(BuildContext context) => const ExpansionTile(
    title: Text('Как устроена оценка'),
    children: [
      Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'Это локальная формула FitLife v1, а не измеренный '
          'индекс Холта. Веса факторов и шкала 1–10 пока не проверены '
          'на пользователях. Учитываем массу, белок, клетчатку, воду '
          'в еде, энергоёмкость и выбранную структуру. Чем больше '
          'пробелов в данных, тем шире возможный диапазон.\n\n'
          'Исследования факторов:\n'
          'Holt et al., 1995 — pubmed.ncbi.nlm.nih.gov/7498104\n'
          'Flood-Obbagy & Rolls, 2009 — pubmed.ncbi.nlm.nih.gov/19110020\n'
          'Rolls et al., 1999 — pubmed.ncbi.nlm.nih.gov/10500012\n\n'
          'Эти работы не подтверждают нашу формулу и не дают '
          'универсального времени сытости.',
        ),
      ),
    ],
  );
}
